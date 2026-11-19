extends RefCounted

# All entries are local prototype data. No real money or remote ranking is used.
func caption(parent: Node, value: String, size: int=18) -> Label:
	var l := Label.new()
	l.text=value
	l.add_theme_font_size_override("font_size",size)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func column(parent: Node, width: float) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x=width
	v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio=width
	v.add_theme_constant_override("separation",8)
	parent.add_child(v)
	return v

func tabs(hud, parent: Node, labels: Array, active: int, action: Callable):
	var row := HBoxContainer.new()
	parent.add_child(row)
	for i in range(labels.size()):
		var b: Button=hud.add_button(row,labels[i],func():action.call(i))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if i==active: b.add_theme_color_override("font_color",Color("ff9c8e"))
	parent.add_child(HSeparator.new())

func news(hud, parent: Node):
	var t: Array=[hud.localized("ข่าวสาร","News","新闻"),hud.localized("กิจกรรม","Events","活动"),hud.localized("อัปเดต","Updates","更新")]
	tabs(hud,parent,t,hud.news_tab,func(i):hud.news_tab=i;hud.news_selected=0;hud.open_page("News"))
	var row := HBoxContainer.new()
	parent.add_child(row)
	var left:=column(row,300)
	row.add_child(VSeparator.new())
	var right:=column(row,730)
	var entries: Array=[
		[[hud.localized("ยินดีต้อนรับสู่ ZMB","Welcome to ZMB","欢迎来到 ZMB"),hud.localized("หมู่บ้านวิญญาณคือพื้นที่ปลอดภัยสำหรับเตรียมตัวก่อนออกล่า","Prepare in Spirit Village before entering the hunting zone.","在灵魂村准备后前往狩猎区。")],[hud.localized("ข้อมูลการทดสอบ","Prototype notice","测试公告"),hud.localized("เกมเวอร์ชันทดสอบออฟไลน์ ยังไม่เปิดบริการออนไลน์","Offline prototype; live servers are not connected.","离线测试版，尚未连接正式服务器。")]],
		[[hud.localized("กิจกรรมในอนาคต","Upcoming events","未来活动"),hud.localized("ยังไม่มีกิจกรรมที่เปิดอยู่ ตารางและรางวัลจะแสดงเมื่อเปิดเซิร์ฟเวอร์","No active events. Schedule and rewards will appear when live servers launch.","暂无活动。正式服务器上线后将显示时间和奖励。")]],
		[[hud.localized("แพตช์ v0.1.20","Patch v0.1.20","版本 v0.1.20"),hud.localized("เพิ่มหน้าประกาศ อันดับ และร้านค้า พร้อมเมนูสามภาษา","News, ranking and shop pages with three-language menus.","新增公告、排行和商店页面，支持三种语言。")],[hud.localized("แพตช์ v0.1.19","Patch v0.1.19","版本 v0.1.19"),hud.localized("เมนูตั้งค่า 7 หมวด และ HUD Editor","Seven settings categories and HUD Editor.","七个设置类别与界面编辑器。")]]
	]
	var list: Array=entries[hud.news_tab]
	for i in range(list.size()):
		var b: Button=hud.add_button(left,list[i][0],func():hud.news_selected=i;hud.open_page("News"))
		b.custom_minimum_size.y=60
		if i==hud.news_selected: b.add_theme_color_override("font_color",Color("ff9c8e"))
	var entry: Array=list[clampi(hud.news_selected,0,list.size()-1)]
	caption(right,entry[0],26)
	var banner := PanelContainer.new()
	banner.custom_minimum_size.y=180
	right.add_child(banner)
	var art := TextureRect.new()
	art.texture=preload("res://assets/menu_icons/news.png")
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.add_child(art)
	caption(right,entry[1],20)
	caption(right,hud.localized("ภาพตัวอย่าง • ข้อมูลทดสอบ","Preview artwork • local test data","预览图片 • 测试数据"),14)

func ranking(hud, parent: Node):
	var labels: Array=[hud.localized("เลเวล","Level","等级"),hud.localized("พลังต่อสู้","Power","战力"),"PvP",hud.localized("ระยะโจมตี","Range","距离"),hud.localized("อาวุธ","Weapon","武器"),hud.localized("กิลด์","Guild","公会")]
	tabs(hud,parent,labels,hud.ranking_tab,func(i):hud.ranking_tab=i;hud.ranking_filter=0;hud.open_page("Ranking"))
	if hud.ranking_tab in [3,4]:
		var filters: Array=[hud.localized("ใกล้","Melee","近程"),hud.localized("กลาง","Mid","中程"),hud.localized("ไกล","Long","远程")] if hud.ranking_tab==3 else [hud.localized("ดาบ","Sword","剑"),hud.localized("ทวน","Spear","枪矛"),hud.localized("ปืน","Gun","枪械"),hud.localized("อื่นๆ","Other","其他")]
		tabs(hud,parent,filters,hud.ranking_filter,func(i):hud.ranking_filter=i;hud.open_page("Ranking"))
	caption(parent,hud.localized("อันดับเซิร์ฟเวอร์ • ยังไม่เชื่อมต่อ","Server ranking • offline","服务器排行 • 未连接"),22)
	var table := GridContainer.new()
	table.columns=5
	table.add_theme_constant_override("h_separation",16)
	table.add_theme_constant_override("v_separation",12)
	parent.add_child(table)
	for title in [hud.localized("อันดับ","Rank","排名"),hud.localized("ชื่อ","Name","名称"),hud.localized("เลเวล","Level","等级"),labels[hud.ranking_tab],hud.localized("กิลด์","Guild","公会")]:
		var l:=caption(table,title)
		l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for i in range(8):
		for value in [str(i+1),"—","—","—","—"]:
			var l:=caption(table,value)
			l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			l.custom_minimum_size.y=30
	caption(parent,hud.localized("ข้อมูลของคุณ (ออฟไลน์)","Your local stats (offline)","本地角色数据"),20)
	caption(parent,"LV %d  •  EXP %d  •  %s %d"%[hud.game.level,hud.game.xp,hud.localized("กำจัดมอนสเตอร์","Monsters defeated","击败怪物"),hud.game.monsters_defeated])

func shop(hud, parent: Node):
	var labels: Array=[hud.localized("ร้านค้าทั่วไป","General shop","普通商店"),hud.localized("ร้านค้าพิเศษ","Special shop","特殊商店"),hud.localized("ประวัติการซื้อ","Purchase history","购买记录")]
	tabs(hud,parent,labels,hud.shop_tab,func(i):hud.shop_tab=i;hud.shop_category=0;hud.shop_selected=-1;hud.open_page("Shop"))
	if hud.shop_tab==2:
		caption(parent,hud.localized("ประวัติการซื้อในเครื่องทดสอบ","Local demo purchase history","本地测试购买记录"),22)
		if hud.shop_history.is_empty(): caption(parent,hud.localized("ยังไม่มีประวัติการซื้อ","No purchases yet","暂无购买记录"))
		for entry in hud.shop_history:
			caption(parent,"%s  |  ×%d  |  %d Gold  |  %s"%[entry.name,entry.qty,entry.total,entry.time])
			parent.add_child(HSeparator.new())
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",6)
	parent.add_child(row)
	var left:=column(row,196)
	row.add_child(VSeparator.new())
	var middle:=column(row,514)
	row.add_child(VSeparator.new())
	var right:=column(row,304)
	var cats: Array=[hud.localized("ทั้งหมด","All","全部"),hud.localized("ยา","Potions","药品"),hud.localized("วัสดุ","Materials","材料"),hud.localized("อุปกรณ์","Equipment","装备")]
	if hud.shop_tab==1: cats=[hud.localized("ทั้งหมด","All","全部"),hud.localized("แฟชั่น","Fashion","时装"),hud.localized("สัตว์เลี้ยง","Pets","宠物"),hud.localized("แพ็กพิเศษ","Packs","礼包")]
	for i in range(cats.size()):
		var b: Button=hud.add_button(left,cats[i],func():hud.shop_category=i;hud.shop_selected=-1;hud.open_page("Shop"))
		if i==hud.shop_category: b.add_theme_color_override("font_color",Color("ff9c8e"))
	var catalog: Array=[{"name":"HP Potion","title":hud.localized("ยาฟื้น HP","HP Potion","生命药"),"price":5,"cat":1,"icon":"HP"},{"name":"MP Potion","title":hud.localized("ยาฟื้น MP","MP Potion","法力药"),"price":5,"cat":1,"icon":"MP"},{"name":"Spirit shard","title":hud.localized("เศษวิญญาณ","Spirit shard","灵魂碎片"),"price":10,"cat":2,"icon":"◆"}]
	if hud.shop_tab==1: catalog=[{"name":"Fashion","title":hud.localized("ชุดแฟชั่น","Fashion outfit","时装"),"price":0,"cat":1,"icon":"◇"},{"name":"Pet","title":hud.localized("สัตว์เลี้ยง","Pet","宠物"),"price":0,"cat":2,"icon":"◇"},{"name":"Pack","title":hud.localized("แพ็กพิเศษ","Special pack","特殊礼包"),"price":0,"cat":3,"icon":"◇"}]
	var products: Array=catalog.filter(func(item):return hud.shop_category==0 or item.cat==hud.shop_category)
	caption(middle,"%s  •  50 %s"%[labels[hud.shop_tab],hud.localized("ช่อง","slots","格")])
	var grid := GridContainer.new()
	grid.columns=10
	grid.add_theme_constant_override("h_separation",3)
	grid.add_theme_constant_override("v_separation",5)
	middle.add_child(grid)
	for i in range(50):
		var occupied:=i<products.size()
		var slot_text: String=""
		if occupied:
			slot_text="%s\n%d G"%[products[i].icon,products[i].price] if hud.shop_tab==0 else products[i].icon
		var b: Button=hud.inventory_slot(grid,slot_text,Vector2(47,52),occupied)
		if occupied:
			b.tooltip_text="%s  •  %d Gold"%[products[i].title,products[i].price]
			b.pressed.connect(func():hud.shop_selected=i;hud.open_page("Shop"))
		else: b.disabled=true
	caption(middle,hud.localized("เลือกสินค้าเพื่อดูราคาและรายละเอียด","Select an item for price and details","选择商品以查看详情"),15)
	caption(right,"Gold: %d"%hud.game.coins,22)
	if hud.shop_selected<0 or hud.shop_selected>=products.size():
		caption(right,hud.localized("กรุณาเลือกสินค้า","Select an item","请选择商品"))
		return
	var product: Dictionary=products[hud.shop_selected]
	caption(right,product.title,24)
	if hud.shop_tab==1:
		caption(right,hud.localized("ตัวอย่างเท่านั้น ยังไม่เปิดซื้อ","Preview only; purchases unavailable","仅供预览，暂不可购买"))
		return
	caption(right,"%d Gold / %s"%[product.price,hud.localized("ชิ้น","item","件")])
	var qty := SpinBox.new()
	qty.min_value=1
	qty.max_value=48
	qty.value=1
	right.add_child(qty)
	var total:=caption(right,"%d Gold"%product.price)
	qty.value_changed.connect(func(v):total.text="%d Gold"%(int(v)*int(product.price)))
	var message:=caption(right,"")
	hud.add_button(right,hud.localized("ซื้อ (ทดสอบ)","Buy (demo)","购买（测试）"),func():
		var amount:=int(qty.value)
		var cost:=amount*int(product.price)
		if hud.game.coins<cost or hud.game.items.size()+amount>48:
			message.text=hud.localized("เงินหรือพื้นที่กระเป๋าไม่พอ","Insufficient gold or bag space","金币或背包空间不足")
			return
		hud.game.coins-=cost
		for i in range(amount): hud.game.items.append(product.name)
		hud.shop_history.push_front({"name":product.name,"qty":amount,"total":cost,"time":Time.get_datetime_string_from_system()})
		hud.open_page("Shop"))
