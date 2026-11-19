extends RefCounted

static func note(h, p: Node):
	h.add_text(p,h.localized("โหมดทดสอบออฟไลน์ • ยังไม่เชื่อมเซิร์ฟเวอร์","Offline test • server not connected","离线测试 • 未连接服务器"))

static func disabled(h,p: Node,t: String):
	var b: Button=h.add_button(p,t,func():pass)
	b.disabled=true
	return b

static func search_box(h,p: Node,t: String) -> LineEdit:
	var input:=LineEdit.new()
	input.placeholder_text=t
	input.custom_minimum_size.y=42
	p.add_child(input)
	return input

static func social(h,p: Node):
	var ui=preload("res://service_pages.gd").new()
	ui.tabs(h,p,[h.localized("เพื่อน","Friends","好友"),h.localized("ปาร์ตี้","Party","队伍"),h.localized("กิลด์","Guild","公会")],h.social_tab,func(i):h.social_tab=i;h.social_sub=0;h.open_page("Social"))
	var subs: Array=[]
	match h.social_tab:
		0: subs=[h.localized("รายชื่อเพื่อน","Friends list","好友列表"),h.localized("คำขอ","Requests","申请"),h.localized("บล็อก","Blocked","黑名单")]
		1: subs=[h.localized("สมาชิก","Members","成员"),h.localized("คำเชิญ","Invitations","邀请"),h.localized("ตั้งค่าแบ่งของ","Loot settings","分配设置")]
		2: subs=[h.localized("ค้นหากิลด์","Find guild","查找公会"),h.localized("กิลด์ของฉัน","My guild","我的公会"),h.localized("สมาชิก","Members","成员")]
	ui.tabs(h,p,subs,h.social_sub,func(i):h.social_sub=i;h.open_page("Social"))
	var row:=HBoxContainer.new()
	p.add_child(row)
	var left: VBoxContainer=ui.column(row,510)
	row.add_child(VSeparator.new())
	var right: VBoxContainer=ui.column(row,510)
	ui.caption(left,subs[h.social_sub],22)
	note(h,left)
	match h.social_tab:
		0:
			search_box(h,left,h.localized("ค้นหาชื่อผู้เล่น","Search player name","搜索玩家"))
			disabled(h,left,h.localized("เพิ่มเพื่อน","Add friend","添加好友"))
			if h.demo_friends.is_empty(): ui.caption(left,h.localized("ยังไม่มีรายชื่อ","No entries","暂无记录"))
			else:
				for who in h.demo_friends: ui.caption(left,str(who)+" [TEST]")
			ui.caption(right,h.localized("แชทส่วนตัว","Private chat","私聊"),22)
			ui.caption(right,h.localized("เลือกเพื่อนที่ออนไลน์เพื่อสนทนา","Select an online friend to chat","选择在线好友聊天"))
			var chat:=search_box(h,right,h.localized("พิมพ์ข้อความ","Type message","输入消息"))
			chat.editable=false
			disabled(h,right,h.localized("ส่งข้อความ","Send","发送"))
			disabled(h,right,h.localized("ลบประวัติ","Clear history","清除记录"))
		1:
			ui.caption(left,h.localized("ตัวละครของคุณ (ยังไม่มีปาร์ตี้)","Your character (no party)","你的角色（未组队）"))
			ui.caption(left,"LV %d  •  HP %d / 100  •  MP %d / 100"%[h.game.level,h.game.hp,h.game.mp])
			for who in h.demo_party: ui.caption(left,str(who)+" • "+h.localized("เชิญแล้ว (จำลอง)","Invited (demo)","已邀请（测试）"))
			ui.caption(right,h.localized("ข้อมูลและโบนัสปาร์ตี้","Party info & bonuses","队伍信息及加成"),22)
			search_box(h,right,h.localized("ชื่อผู้เล่น","Player name","玩家名称"))
			disabled(h,right,h.localized("เชิญเข้าปาร์ตี้","Invite","邀请"))
			var split:=OptionButton.new()
			for t in [h.localized("เก็บเอง","Free loot","自由拾取"),h.localized("สุ่มแบ่ง","Random","随机分配"),h.localized("แบ่งตามลำดับ","Round robin","轮流分配")]: split.add_item(t)
			split.select(h.social_split)
			split.item_selected.connect(func(i):h.social_split=i)
			right.add_child(split)
			ui.caption(right,h.localized("ตัวเลือกทดสอบ ยังไม่มีผลกับผู้เล่นอื่น","Preview preference; no online effect","测试选项，尚无在线效果"))
			disabled(h,right,h.localized("ออกจากปาร์ตี้","Leave party","离开队伍"))
		2:
			search_box(h,left,h.localized("ค้นหาชื่อกิลด์","Search guild name","搜索公会"))
			ui.caption(left,h.localized("อันดับตามเลเวลกิลด์","Ranked by guild level","按公会等级排行"))
			ui.caption(left,h.localized("ยังไม่มีข้อมูลกิลด์","No guild data available","暂无公会数据"))
			ui.caption(right,h.localized("ตรากิลด์ / ข้อมูล / สมาชิกออนไลน์","Emblem / info / online members","徽章 / 信息 / 在线成员"),22)
			for who in h.demo_guild: ui.caption(right,str(who)+" • "+h.localized("เชิญแล้ว (จำลอง)","Invited (demo)","已邀请（测试）"))
			disabled(h,right,h.localized("สมัครเข้ากิลด์","Apply","申请加入"))
			disabled(h,right,h.localized("สร้างกิลด์","Create guild","创建公会"))

static func slots(h,p: Node,count: int, cols: int, size: Vector2, items: Array, selected: Dictionary={}, action: Callable=Callable()):
	var g:=GridContainer.new()
	g.columns=cols
	g.add_theme_constant_override("h_separation",3)
	g.add_theme_constant_override("v_separation",4)
	p.add_child(g)
	for i in range(count):
		var filled:=i<items.size()
		var b: Button=h.inventory_slot(g,("✓" if selected.has(i) else "◆") if filled else "",size,filled)
		if filled:
			b.tooltip_text=str(items[i])
			if selected.has(i): b.modulate=Color("777777")
			if action.is_valid(): b.pressed.connect(func():action.call(i))
		else: b.disabled=true
	return g

static func trade(h,p: Node):
	var ui=preload("res://service_pages.gd").new()
	note(h,p)
	if not h.trade_partner.is_empty(): ui.caption(p,h.localized("คู่แลกเปลี่ยนจำลอง: ","Demo trade partner: ","测试交易对象：")+h.trade_partner)
	var row:=HBoxContainer.new()
	p.add_child(row)
	var bag: VBoxContainer=ui.column(row,510)
	row.add_child(VSeparator.new())
	var own: VBoxContainer=ui.column(row,255)
	row.add_child(VSeparator.new())
	var other: VBoxContainer=ui.column(row,255)
	ui.caption(bag,h.localized("กระเป๋าของฉัน • 48 ช่อง","My bag • 48 slots","我的背包 • 48格"),20)
	slots(h,bag,48,8,Vector2(56,52),h.game.items,h.trade_selected,func(i):
		if h.trade_selected.has(i): h.trade_selected.erase(i)
		elif h.trade_selected.size()<30: h.trade_selected[i]=h.game.items[i]
		h.open_page("Trade"))
	ui.caption(own,h.localized("เสนอของฉัน","My offer","我的报价"),20)
	var offer: Array=h.trade_selected.values()
	slots(h,own,30,5,Vector2(46,43),offer,{},func(i):h.trade_selected.erase(h.trade_selected.keys()[i]);h.open_page("Trade"))
	var money:=SpinBox.new()
	money.min_value=0
	money.max_value=h.game.coins
	money.value=mini(h.trade_gold,h.game.coins)
	money.value_changed.connect(func(v):h.trade_gold=int(v))
	own.add_child(money)
	ui.caption(own,"Gold")
	ui.caption(other,h.localized("ข้อเสนออีกฝ่าย","Other offer","对方报价"),20)
	slots(h,other,30,5,Vector2(46,43),[])
	ui.caption(other,"Gold: —")
	disabled(h,other,h.localized("ยืนยันแลกเปลี่ยน","Confirm trade","确认交易"))
	h.add_button(p,h.localized("ล้างรายการเสนอ","Clear offer","清空报价"),func():h.trade_selected.clear();h.trade_gold=0;h.open_page("Trade"))

static func market(h,p: Node):
	var ui=preload("res://service_pages.gd").new()
	ui.tabs(h,p,[h.localized("ซื้อไอเทม","Buy","购买"),h.localized("ขายไอเทม","Sell","出售"),h.localized("รายการของฉัน","My listings","我的挂单"),h.localized("ประวัติ","History","历史")],h.market_tab,func(i):h.market_tab=i;h.market_selected=-1;h.open_page("Market"))
	note(h,p)
	match h.market_tab:
		0:
			var row:=HBoxContainer.new()
			p.add_child(row)
			var cats: VBoxContainer=ui.column(row,196)
			var list: VBoxContainer=ui.column(row,514)
			var info: VBoxContainer=ui.column(row,304)
			for t in [h.localized("ทั้งหมด","All","全部"),h.localized("อุปกรณ์","Equipment","装备"),h.localized("ยา","Potions","药品"),h.localized("วัสดุ","Materials","材料")]:
				h.add_button(cats,t,func():h.market_filter=t;h.open_page("Market"))
			ui.caption(list,h.localized("หมวด: ","Category: ","类别：")+h.market_filter)
			search_box(h,list,h.localized("ค้นหาไอเทม","Search items","搜索物品"))
			var sort:=OptionButton.new()
			for t in [h.localized("ราคาต่ำไปสูง","Price low to high","价格从低到高"),h.localized("ราคาสูงไปต่ำ","Price high to low","价格从高到低")]: sort.add_item(t)
			sort.select(h.market_sort)
			sort.item_selected.connect(func(i):h.market_sort=i)
			list.add_child(sort)
			ui.caption(list,h.localized("ไม่มีรายการจากผู้เล่นออนไลน์","No online listings","无在线挂单"))
			disabled(h,list,"‹   1   ›")
			ui.caption(info,h.localized("รายละเอียดสินค้า","Item details","物品详情"),22)
			ui.caption(info,"Gold: %d"%h.game.coins)
			disabled(h,info,h.localized("ยืนยันซื้อ","Confirm purchase","确认购买"))
		1:
			var row:=HBoxContainer.new()
			p.add_child(row)
			var bag: VBoxContainer=ui.column(row,510)
			row.add_child(VSeparator.new())
			var info: VBoxContainer=ui.column(row,510)
			ui.caption(bag,h.localized("กระเป๋า • 48 ช่อง","Bag • 48 slots","背包 • 48格"))
			var selected: Dictionary={}
			if h.market_selected>=0: selected[h.market_selected]=true
			slots(h,bag,48,8,Vector2(56,52),h.game.items,selected,func(i):h.market_selected=i;h.open_page("Market"))
			ui.caption(info,h.localized("รายละเอียดการขาย","Sell details","出售详情"),22)
			if h.market_selected<0 or h.market_selected>=h.game.items.size():
				ui.caption(info,h.localized("เลือกไอเทมจากกระเป๋า","Select item from bag","选择背包物品"))
				return
			var name: String=h.game.items[h.market_selected]
			ui.caption(info,name,24)
			var qty:=SpinBox.new()
			qty.min_value=1
			qty.max_value=h.game.items.count(name)
			qty.value=1
			info.add_child(qty)
			ui.caption(info,h.localized("ราคาต่อชิ้น (Gold)","Price per item (Gold)","单价（金）"))
			var price:=SpinBox.new()
			price.min_value=1
			price.max_value=1000000
			price.value=10
			info.add_child(price)
			var total: Label=ui.caption(info,"10 Gold")
			qty.value_changed.connect(func(_v):total.text="%d Gold"%(int(qty.value)*int(price.value)))
			price.value_changed.connect(func(_v):total.text="%d Gold"%(int(qty.value)*int(price.value)))
			h.add_button(info,h.localized("ยืนยันลงขาย (ทดสอบ)","Confirm listing (demo)","确认挂单（测试）"),func():
				var amount:=int(qty.value)
				if h.game.items.count(name)<amount: return
				for i in range(amount): h.game.items.erase(name)
				h.market_listings.append({"name":name,"qty":amount,"price":int(price.value),"time":Time.get_datetime_string_from_system()})
				h.trade_selected.clear()
				h.market_tab=2
				h.market_selected=-1
				h.open_page("Market"))
		2:
			ui.caption(p,h.localized("กำลังขาย / ขายสำเร็จ / หมดเวลา","Active / Sold / Expired","出售中 / 已售 / 已过期"))
			if h.market_listings.is_empty(): ui.caption(p,h.localized("ไม่มีรายการขาย","No listings","暂无挂单"))
			for entry in h.market_listings:
				var row:=HBoxContainer.new()
				p.add_child(row)
				var l: Label=ui.caption(row,"%s ×%d  •  %d Gold / item"%[entry.name,entry.qty,entry.price])
				l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				h.add_button(row,h.localized("ยกเลิก","Cancel","取消"),func():
					if h.game.items.size()+entry.qty>48: return
					for i in range(entry.qty): h.game.items.append(entry.name)
					h.market_listings.erase(entry)
					h.market_history.push_front({"name":entry.name,"qty":entry.qty,"price":entry.price,"time":Time.get_datetime_string_from_system()})
					h.open_page("Market"))
			disabled(h,p,h.localized("รับเงินจากการขาย","Collect proceeds","领取收入"))
		3:
			ui.caption(p,h.localized("รายการ / จำนวน / ราคา / วันเวลา / ค่าธรรมเนียม","Item / Quantity / Price / Date / Fee","物品 / 数量 / 价格 / 日期 / 费用"))
			if h.market_history.is_empty(): ui.caption(p,h.localized("ยังไม่มีประวัติ","No history","暂无记录"))
			for entry in h.market_history:
				ui.caption(p,"%s  ×%d  |  %d Gold  |  %s  |  0  |  %s"%[entry.name,entry.qty,entry.price,entry.time,h.localized("ยกเลิก","Cancelled","已取消")])

static func world_map(h,p: Node):
	var ui=preload("res://service_pages.gd").new()
	var row:=HBoxContainer.new()
	p.add_child(row)
	var left: VBoxContainer=ui.column(row,650)
	var right: VBoxContainer=ui.column(row,360)
	ui.caption(left,h.localized("แผนที่โลก • หมู่บ้านวิญญาณ","World map • Spirit Village","世界地图 • 灵魂村"),22)
	var map=preload("res://minimap.gd").new()
	map.game=h.game
	map.custom_minimum_size=Vector2(600,400)
	left.add_child(map)
	ui.caption(right,h.localized("จุดวาร์ป","Warp points","传送点"),22)
	var points: Array=[Vector3.ZERO,Vector3(0,0,-11),Vector3(11,0,0),Vector3(0,0,11),Vector3(-11,0,0)]
	var titles: Array=[h.localized("หมู่บ้าน (จุดเกิด)","Village (spawn)","村庄（出生点）"),h.localized("ประตูเหนือ","North gate","北门"),h.localized("ประตูตะวันออก","East gate","东门"),h.localized("ประตูใต้","South gate","南门"),h.localized("ประตูตะวันตก","West gate","西门")]
	var option:=OptionButton.new()
	for t in titles: option.add_item(t)
	option.select(h.warp_selected)
	option.item_selected.connect(func(i):h.warp_selected=i)
	right.add_child(option)
	var message: Label=ui.caption(right,h.localized("วาร์ปทดสอบได้เฉพาะในเขตปลอดภัย","Demo warp within safe zone only","仅可在安全区内测试传送"))
	h.add_button(right,h.localized("ยืนยันวาร์ป","Confirm warp","确认传送"),func():
		if not h.game.started or h.game.hp<=0 or not h.game.in_safe_zone():
			message.text=h.localized("กลับเข้าเขตปลอดภัยก่อน","Return to safe zone first","请先返回安全区")
			return
		h.game.player.position=points[h.warp_selected]
		h.game.player.velocity=Vector3.ZERO
		h.game.stick=Vector2.ZERO
		h.close_page())
	ui.caption(right,h.localized("ขาว = ผู้เล่น\nเขียว = เขตปลอดภัย\nแดง = มอนสเตอร์\nทอง = บอส","White = player\nGreen = safe zone\nRed = monsters\nGold = boss","白色 = 玩家\n绿色 = 安全区\n红色 = 怪物\n金色 = 首领"))
