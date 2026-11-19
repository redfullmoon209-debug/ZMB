extends RefCounted

static func run(h, command: String, value: float=0, item: String=""):
	if h.game.gm_execute(command,value,item):
		h.open_page("GM")

static func amount_row(h,p: Node,title: String,command: String,initial: float=1,maximum: float=100000):
	var row:=HBoxContainer.new()
	p.add_child(row)
	var label:=Label.new()
	label.text=title
	label.custom_minimum_size.x=190
	row.add_child(label)
	var spin:=SpinBox.new()
	spin.min_value=1
	spin.max_value=maximum
	spin.value=initial
	spin.custom_minimum_size.x=90
	row.add_child(spin)
	h.add_button(row,"+",func():run(h,command,spin.value))
	h.add_button(row,"−",func():run(h,command,-spin.value))

static func speed_row(h,p: Node,title: String,command: String,initial: float):
	var row:=HBoxContainer.new()
	p.add_child(row)
	h.add_text(row,title)
	var spin:=SpinBox.new()
	spin.min_value=0.25
	spin.max_value=5
	spin.step=0.25
	spin.value=initial
	row.add_child(spin)
	h.add_button(row,h.localized("ใช้ค่า","Apply","应用"),func():run(h,command,spin.value))

static func item_row(h,p: Node):
	var row:=HBoxContainer.new()
	p.add_child(row)
	var items:=OptionButton.new()
	for item in ["HP Potion","MP Potion","Spirit shard"]: items.add_item(item)
	row.add_child(items)
	var qty:=SpinBox.new()
	qty.min_value=1
	qty.max_value=h.game.bag_capacity()
	qty.value=1
	row.add_child(qty)
	h.add_button(row,"+",func():run(h,"item",qty.value,items.get_item_text(items.selected)))
	h.add_button(row,"−",func():run(h,"item",-qty.value,items.get_item_text(items.selected)))

static func disabled(h,p: Node,title: String):
	var b: Button=h.add_button(p,title,func():pass)
	b.disabled=true

static func build(h,p: Node):
	if not h.game.gm_allowed(): return
	var ui=preload("res://service_pages.gd").new()
	ui.tabs(h,p,[h.localized("จัดการตัวละคร","Character management","角色管理"),h.localized("จัดการเซิร์ฟเวอร์","Server management","服务器管理")],h.gm_tab,func(i):h.gm_tab=i;h.open_page("GM"))
	ui.caption(p,h.localized("GM ทดสอบออฟไลน์ • ไม่ใช่สิทธิ์บัญชีออนไลน์","Offline GM test • no live account privileges","离线GM测试 • 非正式账号权限"),16)
	if h.gm_tab==0: character(h,p,ui)
	else: server(h,p,ui)

static func target_picker(h,p: Node,ui):
	var search:=LineEdit.new()
	search.placeholder_text=h.localized("ค้นหามอนสเตอร์ / ผู้เล่น","Search monster / player","搜索怪物 / 玩家")
	p.add_child(search)
	var pick:=OptionButton.new()
	p.add_child(pick)
	var choices: Array=[]
	var fill:=func(query: String):
		pick.clear()
		choices.clear()
		pick.add_item(h.localized("ตัวเอง / ไม่ล็อกเป้า","Self / no target","自己 / 无目标"))
		choices.append(null)
		var nodes: Array=h.game.enemies.duplicate()
		if is_instance_valid(h.game.gm_target) and not nodes.has(h.game.gm_target): nodes.append(h.game.gm_target)
		for n in nodes:
			if not is_instance_valid(n): continue
			var text: String="%s #%d • HP %d"%[["Normal","Elite","Boss"][int(n.get_meta("tier"))],n.get_meta("spawn_index"),n.get_meta("hp")]
			if not query.is_empty() and not text.to_lower().contains(query.to_lower()): continue
			pick.add_item(text)
			choices.append(n)
		pick.select(maxi(0,choices.find(h.game.gm_target)))
	fill.call("")
	search.text_changed.connect(fill)
	h.add_button(p,h.localized("ล็อกเป้าที่เลือก","Lock selected target","锁定所选目标"),func():
		if pick.selected<0 or pick.selected>=choices.size(): return
		h.game.gm_target=choices[pick.selected]
		h.open_page("GM"))
	ui.caption(p,h.localized("ผู้เล่นออนไลน์ยังไม่เชื่อมต่อ","Online players unavailable","在线玩家尚未连接"),14)

static func character(h,p: Node,ui):
	var row:=HBoxContainer.new()
	p.add_child(row)
	var left: VBoxContainer=ui.column(row,520)
	row.add_child(VSeparator.new())
	var right: VBoxContainer=ui.column(row,510)
	var locked: bool=is_instance_valid(h.game.gm_target)
	ui.caption(left,h.localized("เป้าหมายปัจจุบัน","Current target","当前目标"),22)
	ui.caption(left,("Monster #%d • HP %d"%[h.game.gm_target.get_meta("spawn_index"),h.game.gm_target.get_meta("hp")]) if locked else h.localized("ตัวเอง","Self","自己"),20)
	target_picker(h,left,ui)
	h.add_button(left,h.localized("ยกเลิกล็อกเป้า (ตัวเอง)","Clear target (self)","解除锁定（自己）"),func():h.game.gm_target=null;h.game.target=null;h.open_page("GM"))
	ui.caption(left,h.localized("วาร์ปแผนที่","Warp map","地图传送"),22)
	var points:=OptionButton.new()
	for t in [h.localized("หมู่บ้าน","Village","村庄"),"North Gate","East Gate","South Gate","West Gate","Normal Zone","Elite Zone","Boss Zone"]: points.add_item(t)
	left.add_child(points)
	h.add_button(left,h.localized("วาร์ป","Warp","传送"),func():run(h,"warp",points.selected))
	var warp: Button=h.add_button(left,h.localized("วาร์ปไปหาเป้าหมาย","Warp to target","传送到目标"),func():run(h,"warp_target"))
	warp.disabled=not locked
	ui.caption(left,h.localized("สั่งตาย / ฟื้น ตามเป้าปัจจุบัน","Kill / revive current target","击杀 / 复活当前目标"),20)
	var actions:=HBoxContainer.new()
	left.add_child(actions)
	h.add_button(actions,h.localized("สั่งตาย","Kill","击杀"),func():run(h,"kill"))
	h.add_button(actions,h.localized("สั่งฟื้น","Revive","复活"),func():run(h,"revive"))
	ui.caption(right,h.localized("ปรับค่าตัวละคร","Character values","角色数值"),22)
	if locked:
		amount_row(h,right,"HP","hp",10,200)
		ui.caption(right,h.localized("มอนสเตอร์รองรับ HP / ตาย / ฟื้น / วาร์ปเท่านั้น","Monsters support HP, kill, revive and warp only","怪物仅支持生命值、击杀、复活和传送"),16)
		return
	ui.caption(right,"LV %d | EXP %d | Gold %d | HP %d | MP %d"%[h.game.level,h.game.xp,h.game.coins,h.game.hp,h.game.mp],16)
	amount_row(h,right,h.localized("เงิน","Gold","金币"),"gold",100)
	amount_row(h,right,"EXP","exp",100)
	amount_row(h,right,h.localized("เลเวล","Level","等级"),"level",1,1000)
	amount_row(h,right,"HP","hp",10,100)
	amount_row(h,right,"MP","mp",10,100)
	amount_row(h,right,h.localized("พลังโจมตี","Attack power","攻击力"),"attack",10)
	amount_row(h,right,h.localized("พลังป้องกัน","Defense","防御"),"defense",1)
	ui.caption(right,h.localized("ไอเทมทั้งหมดที่มีในเกมทดสอบ","All current demo items","当前测试物品"),20)
	item_row(h,right)
	speed_row(h,right,h.localized("ความเร็ววิ่ง ×","Run speed ×","移动速度 ×"),"move_speed",h.game.gm_move_multiplier)
	speed_row(h,right,h.localized("ความเร็วตี ×","Attack speed ×","攻击速度 ×"),"attack_speed",h.game.gm_attack_multiplier)
	h.add_button(right,h.localized("ปิดอมตะ","Disable invincibility","关闭无敌") if h.game.gm_invincible else h.localized("เปิดอมตะ","Enable invincibility","开启无敌"),func():run(h,"invincible",0 if h.game.gm_invincible else 1))
	h.add_button(right,h.localized("แสดงตัว","Show character","显示角色") if h.game.gm_invisible else h.localized("ล่องหน","Invisible","隐身"),func():run(h,"invisible",0 if h.game.gm_invisible else 1))

static func server(h,p: Node,ui):
	var row:=HBoxContainer.new()
	p.add_child(row)
	var left: VBoxContainer=ui.column(row,260)
	row.add_child(VSeparator.new())
	var right: VBoxContainer=ui.column(row,780)
	var categories: Array=[h.localized("จัดการผู้เล่น","Players","玩家"),h.localized("จัดการไอเทม","Items","物品"),h.localized("จัดการมอนสเตอร์","Monsters","怪物"),h.localized("จัดการกิจกรรม","Events","活动"),h.localized("ประกาศ","Announcements","公告"),h.localized("ตรวจสอบเซิร์ฟเวอร์","Server audit","服务器审计")]
	for i in range(categories.size()):
		var b: Button=h.add_button(left,categories[i],func():h.gm_server_tab=i;h.open_page("GM"))
		if i==h.gm_server_tab: b.add_theme_color_override("font_color",Color("ff9c8e"))
	ui.caption(right,categories[h.gm_server_tab],24)
	match h.gm_server_tab:
		0:
			var name:=LineEdit.new()
			name.placeholder_text=h.localized("ค้นหาชื่อ / ID ผู้เล่น","Search player / ID","搜索玩家 / ID")
			right.add_child(name)
			for title in [h.localized("ค้นหา","Search","搜索"),h.localized("เตะ","Kick","踢出"),h.localized("แบน","Ban","封禁"),h.localized("ปลดแบน","Unban","解封")]: disabled(h,right,title)
			ui.caption(right,h.localized("ต้องเชื่อมบัญชีและเซิร์ฟเวอร์จริง","Requires live accounts and server","需要正式账号及服务器"))
		1:
			h.add_button(right,h.localized("เลือกตัวเองสำหรับทดสอบแจก","Select self for demo grant","选择自己测试发放"),func():h.game.gm_target=null;h.game.target=null;h.open_page("GM"))
			amount_row(h,right,"Gold","gold",100)
			amount_row(h,right,"EXP","exp",100)
			item_row(h,right)
			disabled(h,right,h.localized("แจกผู้เล่นออนไลน์ทั้งหมด / ทั้งเซิร์ฟเวอร์","Grant to all online / whole server","发放给全服 / 在线玩家"))
		2:
			for i in range(3):
				h.add_button(right,["Spawn Normal","Spawn Elite","Spawn Boss"][i],func():run(h,"spawn",i))
			target_picker(h,right,ui)
			var remove: Button=h.add_button(right,h.localized("ลบมอนสเตอร์ที่ล็อก","Remove locked monster","删除锁定怪物"),func():run(h,"remove"))
			remove.disabled=not is_instance_valid(h.game.gm_target)
		3:
			ui.caption(right,h.localized("สถานะกิจกรรมทดสอบ: ","Test event status: ","测试活动状态：")+("ON" if h.game.gm_event_active else "OFF"))
			h.add_button(right,h.localized("เปิดกิจกรรม","Enable event","开启活动"),func():run(h,"event",1))
			h.add_button(right,h.localized("ปิดกิจกรรม","Disable event","关闭活动"),func():run(h,"event",0))
			disabled(h,right,h.localized("กำหนดเวลากิจกรรมออนไลน์","Schedule live event","安排正式活动"))
		4:
			var text:=LineEdit.new()
			text.placeholder_text=h.localized("ข้อความประกาศ","Announcement message","公告内容")
			text.max_length=180
			right.add_child(text)
			h.add_button(right,h.localized("ประกาศในเครื่องทดสอบ","Broadcast locally","本地公告"),func():run(h,"announce",0,text.text))
			disabled(h,right,h.localized("ประกาศทั่วเซิร์ฟเวอร์","Server-wide broadcast","全服公告"))
		5:
			ui.caption(right,h.localized("ผู้เล่นออนไลน์จริง: ยังไม่เชื่อม","Live online count: not connected","正式在线人数：未连接"))
			ui.caption(right,h.localized("ประวัติคำสั่ง GM ในรอบนี้","Local GM command log (session)","本次本地GM日志"),22)
			for line in h.game.gm_logs: ui.caption(right,line,14)
