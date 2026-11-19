extends RefCounted

static func title(hud, id: String) -> String:
	match id:
		"main": return hud.localized("กวาดล้างวิญญาณคลั่ง","Defeat rampaging spirits","消灭狂暴亡灵")
		"side": return hud.localized("เก็บเศษวิญญาณ","Collect spirit shards","收集灵魂碎片")
		"daily": return hud.localized("ล่าบอสวิญญาณ","Hunt spirit bosses","狩猎灵魂首领")
	return ""

static func description(hud, id: String) -> String:
	match id:
		"main": return hud.localized("ออกจากหมู่บ้านปลอดภัยและกำจัดมอนสเตอร์ 30 ตัว","Leave the safe village and defeat 30 monsters.","离开安全村并击败30只怪物。")
		"side": return hud.localized("เก็บเศษวิญญาณที่ดรอปจากมอนสเตอร์ 10 ชิ้น","Collect 10 spirit shards dropped by monsters.","拾取怪物掉落的10个灵魂碎片。")
		"daily": return hud.localized("กำจัดบอสวิญญาณ 3 ตัว ภายในรอบรายวัน","Defeat 3 spirit bosses during the daily period.","在每日周期内击败3个灵魂首领。")
	return ""

static func build(hud, parent: Node):
	var ui=preload("res://service_pages.gd").new()
	var labels: Array=[hud.localized("เควสหลัก","Main","主线"),hud.localized("เควสรอง","Side","支线"),hud.localized("เควสรายวัน","Daily","每日"),hud.localized("เควสสำเร็จ","Completed","已完成")]
	ui.tabs(hud,parent,labels,hud.quest_tab,func(i):
		hud.quest_tab=i
		hud.quest_selected=["main","side","daily",""][i]
		hud.open_page("Quest"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	parent.add_child(row)
	var left: VBoxContainer=ui.column(row,510)
	row.add_child(VSeparator.new())
	var right: VBoxContainer=ui.column(row,510)
	ui.caption(left,hud.localized("รายการภารกิจ","Quest list","任务列表"),22)
	ui.caption(right,hud.localized("รายละเอียดภารกิจ","Quest details","任务详情"),22)
	var ids: Array=[]
	if hud.quest_tab==3:
		for id in ["main","side","daily"]:
			if hud.game.is_quest_claimed(id): ids.append(id)
	else:
		var id: String=["main","side","daily"][hud.quest_tab]
		if not hud.game.is_quest_claimed(id): ids.append(id)
	if ids.is_empty():
		ui.caption(left,hud.localized("ไม่มีภารกิจในหมวดนี้","No quests in this category","此类别暂无任务"))
		return
	if hud.quest_selected not in ids: hud.quest_selected=ids[0]
	for id in ids:
		var b: Button=hud.add_button(left,title(hud,id),func():hud.quest_selected=id;hud.open_page("Quest"))
		b.custom_minimum_size.y=56
		if id==hud.quest_selected: b.add_theme_color_override("font_color",Color("ff9c8e"))
		var status: Label=ui.caption(left,"")
		hud.quest_list_status[id]=status
	var selected: String=hud.quest_selected
	ui.caption(right,title(hud,selected),26)
	ui.caption(right,description(hud,selected))
	hud.quest_detail_status=ui.caption(right,"")
	hud.quest_detail_bar=ProgressBar.new()
	hud.quest_detail_bar.max_value=hud.game.quest_goal(selected)
	hud.quest_detail_bar.custom_minimum_size.y=30
	right.add_child(hud.quest_detail_bar)
	right.add_child(HSeparator.new())
	ui.caption(right,hud.localized("รางวัล","Reward","奖励"),22)
	ui.caption(right,"%d Gold"%hud.game.quest_reward(selected))
	if selected=="daily":
		hud.quest_countdown=ui.caption(right,"")
		ui.caption(right,hud.localized("เวลาทดสอบจากเครื่อง (UTC) • เซิร์ฟเวอร์จะควบคุมเมื่อเปิดจริง","Local test clock (UTC); server controls live reset","本地测试时间（UTC），正式版由服务器管理"),14)
	if hud.game.is_quest_claimed(selected):
		ui.caption(right,hud.localized("รับรางวัลแล้ว","Reward claimed","已领取奖励"))
	else:
		hud.add_button(right,hud.localized("ติดตาม / ยกเลิกติดตาม","Track / untrack","追踪 / 取消追踪"),func():
			hud.tracked_quest="" if hud.tracked_quest==selected else selected
			hud.close_page())
		hud.quest_claim_button=hud.add_button(right,hud.localized("รับรางวัล","Claim reward","领取奖励"),func():
			if hud.game.claim_quest(selected):
				if hud.tracked_quest==selected: hud.tracked_quest=""
				hud.quest_tab=3
				hud.open_page("Quest"))
	hud.update_quest_ui()
