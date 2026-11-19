extends CanvasLayer
var game: Node3D
var root: Control
var stats: Label
var target_label: Label
var zone_label: Label
var camera_mode_button: Button
var panel: PanelContainer
var body: VBoxContainer
var chat: LineEdit
var joystick: Button
var lang := 1
var selected_page := ""
var buttons: Array[Button] = []
var touch_actions: Dictionary = {}
var captured_touches: Dictionary = {}
var camera_touches: Dictionary = {}
var joystick_finger := -1
var web_diagnostics := false
var diagnostic_timer := 0.0
var browser_window: JavaScriptObject
var start_button: Button
var close_button: Button
var modal_scroll: ScrollContainer
var scroll_finger := -1
var scroll_start := Vector2.ZERO
var scroll_start_value := 0
var scroll_dragged := false
var swallow_scroll_release := false
var menu_items: Dictionary = {}
const UHD = "res://assets/uhd/"
const INVENTORY_PAGES = ["Bag","Character","Storage","Skills"]
var meter_fills: Array[TextureProgressBar] = []
var character_values: Dictionary = {}
const MENU_PAGES = ["Bag","Quest","Social","Trade","Market","Shop","Ranking","News","Map","Settings"]
var config := ConfigFile.new()
var names := {"Bag":["กระเป๋า","Bag","背包"],"Storage":["คลัง","Storage","仓库"],"Character":["ข้อมูลตัวละคร","Character","角色信息"],"Skills":["สกิล","Skills","技能"],"Market":["ตลาดโลก","Market","市场"],"Shop":["ร้านค้า","Shop","商店"],"Quest":["เควส","Quest","任务"],"Social":["สังคม","Social","社交"],"Ranking":["อันดับ","Ranking","排行"],"News":["ประกาศ","News","公告"],"Settings":["ตั้งค่า","Settings","设置"],"Trade":["แลกเปลี่ยน","Trade","交易"],"Map":["แผนที่","Map","地图"]}

func trn(s: String) -> String:
	return names[s][lang] if names.has(s) else s

func localized(th: String, en: String, zh: String) -> String:
	return [th,en,zh][lang]

func _ready():
	config.load("user://zmb.cfg")
	lang=int(config.get_value("ui","lang",1))
	root=Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	var style := StyleBoxFlat.new()
	style.bg_color=Color("20252cdd")
	style.border_color=Color("9da4ac")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	theme.set_stylebox("normal","Button",style)
	var active := style.duplicate() as StyleBoxFlat
	active.bg_color=Color("802a38")
	theme.set_stylebox("hover","Button",active)
	theme.set_stylebox("pressed","Button",active)
	var popup := style.duplicate() as StyleBoxFlat
	popup.bg_color=Color("14191ffa")
	popup.border_color=Color("a64a4e")
	theme.set_stylebox("panel","PanelContainer",popup)
	theme.default_font_size=18
	var ui_font := preload("res://assets/fonts/NotoSansThai-Regular.ttf")
	ui_font.fallbacks = [preload("res://assets/fonts/ZMB-Chinese.otf"),ThemeDB.fallback_font]
	theme.default_font=ui_font
	root.theme=theme
	stats=label("",Vector2(22,18),Vector2(320,100))
	# Decorative meters do not participate in touch routing.
	for i in range(3):
		var meter := TextureProgressBar.new()
		meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
		meter.position=Vector2(22,110+i*17)
		meter.texture_under=load(UHD+["03_HP_Track.png","04_MP_Track.png","05_EXP_Track.png"][i])
		meter.texture_progress=load(UHD+["07_HP_Fill.png","08_MP_Fill.png","09_EXP_Fill.png"][i])
		meter.nine_patch_stretch=true
		meter.size=Vector2(220,16)
		meter.max_value=100
		root.add_child(meter)
		meter_fills.append(meter)
	target_label=label("",Vector2(460,18),Vector2(360,70))
	target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	zone_label=label("",Vector2(420,76),Vector2(440,34))
	zone_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	zone_label.add_theme_font_size_override("font_size",21)
	make_button("MENU",Vector2(1110,18),Vector2(145,52),func(): open_page("Menu"))
	joystick=make_button("◉",Vector2(40,480),Vector2(150,150),func(): pass)
	joystick.gui_input.connect(_stick_event)
	make_button("ATTACK",Vector2(1090,500),Vector2(125,95),func(): game.attack(0))
	for i in range(3):
		make_button("SKILL %d"%(i+1),Vector2(880+i*110,405),Vector2(100,60),func():game.attack(i+1))
	make_button("JUMP",Vector2(1090,325),Vector2(95,55),func():game.jump_requested=true)
	make_button("DASH",Vector2(1190,325),Vector2(80,55),func():game.dash_time=0.18)
	make_button("RUN",Vector2(220,550),Vector2(80,55),func():game.run_mode=not game.run_mode)
	make_button("LOOT",Vector2(980,550),Vector2(90,55),func():game.collect())
	make_button("AUTO",Vector2(880,550),Vector2(90,55),func():
		if not game.in_safe_zone(): game.auto=not game.auto)
	make_button("MONSTER",Vector2(1000,250),Vector2(125,55),func():game.choose_target())
	make_button("PLAYER",Vector2(1135,250),Vector2(120,55),func(): target_label.text="No online players (demo)")
	make_button("HP",Vector2(480,565),Vector2(80,55),func():game.hp=minf(100,game.hp+35))
	make_button("MP",Vector2(570,565),Vector2(80,55),func():game.mp=minf(100,game.mp+35))
	make_button("+ ZOOM",Vector2(880,20),Vector2(100,48),func():game.zoom=maxf(4,game.zoom-1))
	make_button("- ZOOM",Vector2(985,20),Vector2(100,48),func():game.zoom=minf(16,game.zoom+1))
	game.set_camera_follow(bool(config.get_value("camera","follow",false)))
	camera_mode_button=make_button("CAMERA",Vector2(1040,105),Vector2(215,56),func():
		game.set_camera_follow(not game.camera_follow)
		config.set_value("camera","follow",game.camera_follow)
		config.save("user://zmb.cfg"))
	chat=LineEdit.new()
	chat.placeholder_text="Chat • local demo"
	chat.position=Vector2(430,665)
	chat.size=Vector2(420,40)
	chat.modulate.a=0.35
	chat.focus_entered.connect(func(): chat.modulate.a=1)
	chat.focus_exited.connect(func(): chat.modulate.a=0.35)
	chat.text_submitted.connect(func(_s): chat.clear(); chat.release_focus())
	root.add_child(chat)
	open_page("Start")
	if OS.has_feature("web"):
		browser_window = JavaScriptBridge.get_interface("window")
		web_diagnostics = true
		print("ZMB native touch controls ready")

func label(t: String,p:Vector2,s:Vector2) -> Label:
	var l := Label.new()
	l.text=t
	l.position=p
	l.size=s
	root.add_child(l)
	return l

func make_button(t:String,p:Vector2,s:Vector2,action:Callable) -> Button:
	var b := Button.new()
	b.text=t
	b.set_meta("hud_key",t)
	b.position=config.get_value("position",t,p)
	b.size=config.get_value("size",t,s)
	b.scale=config.get_value("scale",t,Vector2.ONE)
	b.modulate.a=config.get_value("opacity",t,0.82)
	b.pressed.connect(action)
	touch_actions[b] = action
	root.add_child(b)
	buttons.append(b)
	return b

func _stick_event(e):
	if joystick_finger >= 0:
		return
	if e is InputEventMouseButton:
		game.stick=Vector2.ZERO if not e.pressed else ((e.position-joystick.size/2)/70.0).limit_length()
	elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		game.stick=((e.position-joystick.size/2)/70.0).limit_length()

func _set_touch_stick(pos: Vector2):
	var rect := joystick.get_global_rect()
	game.stick = ((pos - rect.get_center()) / maxf(1.0, minf(rect.size.x, rect.size.y) * 0.46)).limit_length()

func _web_rect(control: Control) -> Array:
	# Canvas stretch includes letterbox offsets on wide phones. Convert both
	# corners to actual window pixels before normalizing to DOM coordinates.
	var transform := get_viewport().get_final_transform()
	var window_size := Vector2(get_window().size)
	var rect := control.get_global_rect()
	var first := (transform * rect.position) / window_size
	var last := (transform * rect.end) / window_size
	return [first.x, first.y, last.x, last.y]

func _touch_start(index: int, pos: Vector2) -> bool:
	if is_instance_valid(panel) or not game.started:
		return false
	for i in range(buttons.size()-1, -1, -1):
		var button := buttons[i]
		if not button.is_visible_in_tree() or button.disabled or not button.get_global_rect().has_point(pos):
			continue
		captured_touches[index] = button
		if button == joystick:
			if joystick_finger == -1:
				joystick_finger = index
				_set_touch_stick(pos)
		else:
			var action: Callable = touch_actions[button]
			action.call()
		return true
	if not game.in_safe_zone() and not chat.get_global_rect().has_point(pos):
		var nearest := 65.0
		for enemy in game.enemies:
			if game.camera.is_position_behind(enemy.position): continue
			var distance: float = game.camera.unproject_position(enemy.position + Vector3.UP).distance_to(pos)
			if distance < nearest:
				nearest = distance
				game.target = enemy
	return false

func _touch_move(index: int, pos: Vector2) -> bool:
	if not captured_touches.has(index): return false
	if index == joystick_finger: _set_touch_stick(pos)
	return true

func _touch_end(index: int) -> bool:
	if not captured_touches.has(index): return false
	captured_touches.erase(index)
	if index == joystick_finger:
		joystick_finger = -1
		game.stick = Vector2.ZERO
	return true

func _reset_touches():
	captured_touches.clear()
	camera_touches.clear()
	scroll_finger=-1
	scroll_dragged=false
	swallow_scroll_release=false
	joystick_finger = -1
	game.stick = Vector2.ZERO

func _modal_scroll_input(event: InputEvent) -> bool:
	if not is_instance_valid(modal_scroll): return false
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			var bar := modal_scroll.get_v_scroll_bar()
			if scroll_finger==-1 and modal_scroll.get_global_rect().has_point(event.position) and bar.max_value-bar.page>1:
				scroll_finger=event.index
				scroll_start=event.position
				scroll_start_value=modal_scroll.scroll_vertical
				scroll_dragged=false
				swallow_scroll_release=false
		elif scroll_finger==event.index:
			var was_dragged := scroll_dragged
			scroll_finger=-1
			scroll_dragged=false
			swallow_scroll_release=was_dragged
			return was_dragged
	elif event is InputEventScreenDrag and event.index==scroll_finger:
		var displacement: float = event.position.y-scroll_start.y
		if not scroll_dragged and absf(displacement)>12.0:
			scroll_dragged=true
			# Cancel an emulated press on a child button before scrolling so a
			# swipe never accidentally activates a menu or a spin-box button.
			var release := InputEventMouseButton.new()
			release.button_index=MOUSE_BUTTON_LEFT
			release.position=Vector2(-100,-100)
			release.pressed=false
			get_viewport().push_input(release,true)
		if scroll_dragged:
			modal_scroll.scroll_vertical=int(scroll_start_value-displacement)
			return true
	return false

func _input(event: InputEvent):
	if not is_instance_valid(joystick):
		return
	# Godot's mouse emulation represents only one finger. HUD controls use
	# actual touch indices instead, while popup menus still use mouse emulation.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseButton and event.pressed: swallow_scroll_release=false
		if scroll_dragged or swallow_scroll_release:
			if event is InputEventMouseButton and not event.pressed: swallow_scroll_release=false
			get_viewport().set_input_as_handled()
			return
		if not captured_touches.is_empty() or not camera_touches.is_empty():
			get_viewport().set_input_as_handled()
		return
	if _modal_scroll_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if _touch_end(event.index):
				get_viewport().set_input_as_handled()
			elif camera_touches.erase(event.index):
				get_viewport().set_input_as_handled()
			return
		if _touch_start(event.index, event.position):
			get_viewport().set_input_as_handled()
		elif game.started and not is_instance_valid(panel) and event.position.x > get_viewport().get_visible_rect().size.x*0.35 and not chat.get_global_rect().has_point(event.position):
			camera_touches[event.index]=true
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _touch_move(event.index, event.position): get_viewport().set_input_as_handled()
		elif camera_touches.has(event.index):
			game.rotate_camera(event.relative)
			get_viewport().set_input_as_handled()

func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(game):
		_reset_touches()

func _process(delta):
	if not is_instance_valid(stats): return
	if selected_page=="Character": refresh_character_details()
	if meter_fills.size()==3:
		meter_fills[0].value=game.hp
		meter_fills[1].value=game.mp
		meter_fills[2].value=game.xp
	stats.text="ZMB v0.1.11  |  LV %d  |  Touch %d\nHP %d / 100    MP %d / 100\nEXP %d / 100   Gold %d"%[game.level,captured_touches.size(),game.hp,game.mp,game.xp,game.coins]
	camera_mode_button.text=(["กล้อง: ตามหลัง","CAM: FOLLOW","镜头：跟随"][lang] if game.camera_follow else ["กล้อง: อิสระ","CAM: FREE","镜头：自由"][lang])
	var safe: bool = game.in_safe_zone()
	zone_label.text=(["เขตปลอดภัย • ฟื้นฟู HP/MP","SAFE ZONE • HP/MP recovery","安全区 • 恢复生命与法力"][lang] if safe else ["เขตล่ามอนสเตอร์ • LV 1+","HUNTING ZONE • LV 1+","狩猎区 • LV 1+"][lang])
	zone_label.modulate=Color("a7f2bd") if safe else Color("ffaf83")
	if safe: target_label.text=["หมู่บ้านวิญญาณ — ออกประตูเพื่อเก็บเลเวล","Spirit Village — Exit a gate to hunt","灵魂村 — 出城狩猎"][lang]
	elif is_instance_valid(game.target): target_label.text="%s • HP %d"%[["Normal","Elite","Boss"][game.target.get_meta("tier")],game.target.get_meta("hp")]
	elif game.auto: target_label.text="AUTO HUNT"
	else: target_label.text="ZMB  •  OFFLINE DEMO"
	if game.hp<=0 and game.started and not is_instance_valid(panel): open_page("Revive")
	# Read-only local gameplay diagnostics used by the exported-Web smoke test.
	diagnostic_timer -= delta
	if web_diagnostics and diagnostic_timer <= 0:
		diagnostic_timer = 0.10
		var controls := {}
		for b in buttons: controls[b.get_meta("hud_key",b.text)] = _web_rect(b)
		if is_instance_valid(start_button): controls["START"] = _web_rect(start_button)
		if is_instance_valid(close_button): controls["CLOSE"] = _web_rect(close_button)
		var menu_rects := {}
		for key in menu_items: menu_rects[key]=_web_rect(menu_items[key])
		var d := {"version":"0.1.11","ready":true,"started":game.started,"safe":safe,"hp":game.hp,"mp":game.mp,"camera_follow":game.camera_follow,"pitch":game.pitch,"yaw":game.yaw,"facing":game.player_visual.rotation.y,"page":selected_page,"menu_items":menu_rects,"scroll_rect":_web_rect(modal_scroll) if is_instance_valid(modal_scroll) else [],"scroll_value":modal_scroll.scroll_vertical if is_instance_valid(modal_scroll) else 0,"controls":controls,"stick":[game.stick.x,game.stick.y],"touches":captured_touches.size(),"position":[game.player.position.x,game.player.position.y,game.player.position.z],"velocity":[game.player.velocity.x,game.player.velocity.y,game.player.velocity.z]}
		var payload := JSON.stringify(d)
		if browser_window != null:
			browser_window.zmbDiagnosticsJSON = payload

func close_page():
	character_values.clear()
	if is_instance_valid(panel): panel.queue_free()
	panel=null
	close_button=null
	modal_scroll=null
	menu_items.clear()
	scroll_finger=-1
	scroll_dragged=false
	selected_page=""

func add_button(parent:Node,t:String,action:Callable):
	var b := Button.new()
	b.text=t
	b.custom_minimum_size=Vector2(0,42)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func add_text(parent:Node,t:String):
	var l := Label.new()
	l.text=t
	parent.add_child(l)

func language_menu(parent: Node, page: String):
	var button := MenuButton.new()
	button.text=localized("ภาษา","Language","语言")
	button.custom_minimum_size=Vector2(120,44)
	parent.add_child(button)
	var popup := button.get_popup()
	popup.theme=root.theme
	for i in range(3):
		popup.add_radio_check_item(["ไทย","English","简体中文"][i],i)
		popup.set_item_checked(i,i==lang)
	popup.id_pressed.connect(func(id):
		lang=id
		config.set_value("ui","lang",lang)
		config.save("user://zmb.cfg")
		open_page(page))

func inventory_slot(parent: Node, caption: String, slot_size: Vector2, filled := false) -> Button:
	var b := Button.new()
	b.text=caption
	b.tooltip_text=caption if not caption.is_empty() else localized("ว่าง","Empty","空")
	b.custom_minimum_size=slot_size
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",13)
	var style := StyleBoxTexture.new()
	style.texture=preload("res://assets/uhd/slot.png")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,2)
	b.add_theme_stylebox_override("normal",style)
	var hover := style.duplicate() as StyleBoxTexture
	hover.modulate_color=Color("ffb3b3")
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("pressed",hover)
	if filled: b.modulate=Color("ffe4b4")
	parent.add_child(b)
	return b

func inventory_grid(parent: Node, count: int, columns: int, contents: Array=[]):
	var g := GridContainer.new()
	g.columns=columns
	g.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation",5)
	g.add_theme_constant_override("v_separation",5)
	parent.add_child(g)
	for i in range(count):
		var filled := i<contents.size()
		var b := inventory_slot(g,"◆" if filled else "",Vector2(56,56),filled)
		if filled: b.tooltip_text=str(contents[i])
	return g

func character_preview(parent: Node):
	var vc := SubViewportContainer.new()
	vc.custom_minimum_size=Vector2(185,300)
	vc.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	vc.size_flags_vertical=Control.SIZE_EXPAND_FILL
	vc.mouse_filter=Control.MOUSE_FILTER_IGNORE
	vc.stretch=true
	parent.add_child(vc)
	var vp := SubViewport.new()
	vp.own_world_3d=true
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vc.add_child(vp)
	var model: Node3D=game.player_visual.duplicate()
	model.position=Vector3.ZERO
	model.rotation=Vector3(0,PI,0)
	vp.add_child(model)
	var cam := Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=2.6
	cam.position=Vector3(0,1.1,4)
	vp.add_child(cam)
	cam.look_at(Vector3(0,1.0,0))
	cam.current=true
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-35,25,0)
	light.light_energy=1.6
	vp.add_child(light)
	var env := WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=0.65
	vp.add_child(env)

func equipment_preview(parent: Node):
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	parent.add_child(row)
	var left := VBoxContainer.new()
	row.add_child(left)
	for title in [localized("ศีรษะ","Head","头部"),localized("เสื้อ","Armor","护甲"),localized("ถุงมือ","Gloves","手套"),localized("กางเกง","Legs","裤子"),localized("รองเท้า","Boots","鞋子")]:
		inventory_slot(left,title,Vector2(86,57))
	character_preview(row)
	var right := VBoxContainer.new()
	row.add_child(right)
	for title in [localized("อาวุธหลัก","Main weapon","主武器"),localized("อาวุธรอง","Off hand","副武器"),localized("สัตว์เก็บของ","Loot pet","拾取宠物")]:
		inventory_slot(right,title,Vector2(86,70))
	var accessories := HBoxContainer.new()
	parent.add_child(accessories)
	for title in [localized("กำไล","Bracelet","手镯"),localized("แหวน","Ring","戒指"),localized("สร้อย","Necklace","项链"),localized("แหวน","Ring","戒指"),localized("กำไล","Bracelet","手镯")]:
		inventory_slot(accessories,title,Vector2(60,45))

func format_playtime(seconds: int) -> String:
	return "%02d:%02d:%02d"%[int(seconds/3600.0),int(seconds/60.0)%60,seconds%60]

func build_character_details(parent: VBoxContainer):
	parent.add_theme_constant_override("separation",3)
	var spacer := Control.new()
	spacer.custom_minimum_size.y=20
	parent.add_child(spacer)
	var title := Label.new()
	title.text=localized("ข้อมูลและพลังตัวละคร","Character statistics","角色属性")
	title.add_theme_font_size_override("font_size",18)
	parent.add_child(title)
	parent.add_child(HSeparator.new())
	var details := GridContainer.new()
	details.columns=2
	details.add_theme_constant_override("h_separation",16)
	details.add_theme_constant_override("v_separation",0)
	parent.add_child(details)
	var fields := {
		"level":localized("เลเวล","Level","等级"),
		"gender":localized("เพศ","Gender","性别"),
		"weapon":localized("สายอาวุธ","Weapon type","武器类型"),
		"hp":localized("พลังชีวิต","Health","生命值"),
		"mp":localized("พลังเวท","Mana","法力值"),
		"xp":localized("ค่าประสบการณ์","Experience","经验值"),
		"attack":localized("พลังโจมตีพื้นฐาน","Base attack","基础攻击"),
		"defense":localized("พลังป้องกัน","Defense","防御"),
		"range":localized("ระยะโจมตี","Attack range","攻击距离"),
		"attack_speed":localized("ความเร็วโจมตี","Attack speed","攻击速度"),
		"movement":localized("ความเร็วเคลื่อนที่","Movement speed","移动速度"),
		"kills":localized("มอนสเตอร์ที่กำจัด","Monsters defeated","击败怪物"),
		"gold":localized("เงิน","Gold","金币"),
		"session":localized("เวลาออนไลน์รอบนี้","Session time","本次在线时长"),
		"total":localized("ชั่วโมงออนไลน์สะสม","Total playtime","累计在线时长"),
		"registered":localized("เวลาสมัครบัญชี","Account registration","账号注册时间"),
		"first_play":localized("เข้าเกมครั้งแรก (เครื่อง)","First local entry","首次本地登录")
	}
	for key in fields:
		var name_label := Label.new()
		name_label.text=fields[key]
		name_label.add_theme_font_size_override("font_size",13)
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		details.add_child(name_label)
		var value := Label.new()
		value.add_theme_font_size_override("font_size",13)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_color_override("font_color",Color("e8d4b6"))
		details.add_child(value)
		character_values[key]=value
	var notice := Label.new()
	notice.text=localized("ข้อมูลทดสอบในเครื่อง • ยังไม่ใช่หลักฐานจากเซิร์ฟเวอร์","Local demo data • not server-verified","本地测试数据 • 未经服务器验证")
	notice.add_theme_font_size_override("font_size",13)
	notice.modulate=Color("afb1b8")
	parent.add_child(notice)
	refresh_character_details()

func refresh_character_details():
	if character_values.is_empty(): return
	var values := {
		"level":str(game.level),
		"gender":localized("ชาย","Male","男") if game.male else localized("หญิง","Female","女"),
		"weapon":[localized("ดาบ","Sword","剑"),localized("ทวน","Spear","枪"),localized("ปืน","Gun","火枪")][game.weapon],
		"hp":"%d / 100"%game.hp,
		"mp":"%d / 100"%game.mp,
		"xp":"%d / 100"%game.xp,
		"attack":"15",
		"defense":"—",
		"range":"%.1f m"%[2.7,5.5,12.0][game.weapon],
		"attack_speed":"%.2f / s"%(1.0/0.45),
		"movement":"%.1f m/s"%(18.0 if game.dash_time>0 else (8.0 if game.run_mode else 4.5)),
		"kills":str(game.monsters_defeated),
		"gold":str(game.coins),
		"session":format_playtime(game.session_seconds()),
		"total":format_playtime(game.total_play_seconds()),
		"registered":localized("ยังไม่มีบัญชี","No account yet","暂无账号"),
		"first_play":Time.get_datetime_string_from_unix_time(game.first_play_unix,true).left(16)+" UTC" if game.first_play_unix>0 else "—"
	}
	for key in values:
		var value: Label=character_values[key]
		if is_instance_valid(value): value.text=values[key]

func build_inventory_page(content: Node, page: String):
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	content.add_child(row)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	for column in [left,right]:
		column.custom_minimum_size.x=490
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation",8)
	row.add_child(left)
	row.add_child(VSeparator.new())
	row.add_child(right)
	match page:
		"Bag":
			add_text(left,localized("อุปกรณ์สวมใส่","Equipment","装备"))
			equipment_preview(left)
			add_text(right,localized("กระเป๋า","Inventory","背包")+"  %d / 48"%game.items.size())
			inventory_grid(right,48,8,game.items)
			add_text(right,localized("เงิน","Gold","金币")+"  %d"%game.coins)
		"Storage":
			add_text(left,localized("คลัง (ตัวอย่าง)","Storage (preview)","仓库（预览）"))
			inventory_grid(left,48,8)
			add_text(right,localized("กระเป๋า","Inventory","背包"))
			inventory_grid(right,48,8,game.items)
		"Character":
			character_preview(left)
			build_character_details(right)
		"Skills":
			character_preview(left)
			add_text(right,localized("สกิลอาวุธ","Weapon skills","武器技能"))
			for i in range(3): add_button(right,[localized("ดาบ / ระยะใกล้","Sword / melee","剑 / 近战"),localized("ทวน / ระยะกลาง","Spear / mid","枪 / 中距离"),localized("ปืน / ระยะไกล","Gun / ranged","火枪 / 远程")][i],func():game.weapon=i)
			inventory_grid(right,15,5,["Strike","Spirit thrust","Sweep"])

func grid(parent:Node,count:int,columns:int,contents:Array=[]):
	var g := GridContainer.new()
	g.columns=columns
	parent.add_child(g)
	for i in range(count):
		var b := Button.new()
		b.text="◆" if i<contents.size() else "·"
		b.tooltip_text=str(contents[i]) if i<contents.size() else "Empty"
		b.custom_minimum_size=Vector2(48,42)
		var slot_style := StyleBoxTexture.new()
		slot_style.texture=preload("res://assets/uhd/slot.png")
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			slot_style.set_content_margin(side,1)
		b.add_theme_stylebox_override("normal",slot_style)
		g.add_child(b)
	return g

func build_quick_menu():
	# A single horizontal strip, with the first category anchored on the
	# right next to MENU. All categories fit within the landscape viewport.
	panel.position=Vector2(215,82)
	panel.size=Vector2(1040,112)
	panel.z_index=20
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.layout_direction=Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation",6)
	margin.add_child(row)
	for key in MENU_PAGES:
		var b := Button.new()
		b.text=trn(key)
		b.tooltip_text=trn(key)
		b.custom_minimum_size=Vector2(82,94)
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.clip_text=true
		b.icon=load("res://assets/menu_icons/"+key.to_lower()+".png")
		if key in ["Market","Trade"]:
			b.icon=load(UHD+key.to_lower()+".png")
		b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width",38)
		b.add_theme_font_size_override("font_size",16)
		b.pressed.connect(func():open_page(key))
		row.add_child(b)
		menu_items[key]=b

func open_page(page:String):
	if page=="Menu" and selected_page=="Menu":
		close_page()
		return
	joystick_finger = -1
	camera_touches.clear()
	game.stick = Vector2.ZERO
	close_page()
	selected_page=page
	panel=PanelContainer.new()
	root.add_child(panel)
	if page=="Menu":
		build_quick_menu()
		return
	panel.position=Vector2(175,100)
	panel.size=Vector2(930,520)
	if page in INVENTORY_PAGES:
		panel.position=Vector2(40,28)
		panel.size=Vector2(1200,664)
	panel.z_index=10
	panel.clip_contents=true
	var popup_style := StyleBoxTexture.new()
	popup_style.texture=preload("res://assets/uhd/popup.png")
	# The source texture has transparent outer padding. Draw only the actual
	# artwork rectangle, so the visible frame matches the layout bounds.
	popup_style.region_rect=Rect2(8,36,1660,871)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		popup_style.set_content_margin(side,1)
	panel.add_theme_stylebox_override("panel",popup_style)
	var margin := MarginContainer.new()
	# The original PNG includes transparent padding above and below its frame.
	# Inset controls past the visible metal border, not just the texture bounds.
	margin.add_theme_constant_override("margin_left",40)
	margin.add_theme_constant_override("margin_right",40)
	margin.add_theme_constant_override("margin_top",68 if page in INVENTORY_PAGES else 48)
	margin.add_theme_constant_override("margin_bottom",42)
	panel.add_child(margin)
	body=VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	margin.add_child(body)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	body.add_child(header)
	var title := Label.new()
	title.text="ZMB  /  "+trn(page)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(title)
	if page in INVENTORY_PAGES:
		for key in INVENTORY_PAGES:
			var tab: Button=add_button(header,trn(key),func():open_page(key))
			tab.custom_minimum_size=Vector2(110,44)
			if key==page: tab.add_theme_color_override("font_color",Color("ff9c8e"))
	language_menu(header,page)
	if page not in ["Start","Revive"]:
		close_button=add_button(header,"×",close_page)
		close_button.custom_minimum_size=Vector2(44,44)
	if page in INVENTORY_PAGES:
		body.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	modal_scroll=scroll
	scroll.scroll_deadzone=12
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	match page:
		"Start":
			add_text(content,"ZMB • SPIRIT PLAGUE\nAncient China | Offline prototype\nSelect a character to enter the village.")
			start_button=add_button(content,"Male warrior",func():game.begin(true);close_page())
			add_button(content,"Female warrior",func():game.begin(false);close_page())
		"Bag","Storage","Character","Skills":
			build_inventory_page(content,page)
		"Settings":
			add_text(content,"HUD Editor • position / size / opacity")
			for b in buttons:
				var row := HBoxContainer.new()
				content.add_child(row)
				add_text(row,b.text)
				for axis in ["X","Y","Scale","Alpha"]:
					add_text(row,axis)
					var spin := SpinBox.new()
					spin.min_value=0.2 if axis=="Scale" or axis=="Alpha" else 0
					spin.max_value=2 if axis=="Scale" else (1 if axis=="Alpha" else 1280)
					spin.step=0.05 if axis in ["Scale","Alpha"] else 5
					spin.value=b.position.x if axis=="X" else (b.position.y if axis=="Y" else (b.scale.x if axis=="Scale" else b.modulate.a))
					spin.value_changed.connect(func(v):
						match axis:
							"X": b.position.x=v
							"Y": b.position.y=v
							"Scale": b.scale=Vector2.ONE*v
							"Alpha": b.modulate.a=v
						var key: String=b.get_meta("hud_key",b.text)
						config.set_value("position",key,b.position)
						config.set_value("opacity",key,b.modulate.a)
						config.set_value("scale",key,b.scale)
						config.save("user://zmb.cfg"))
					row.add_child(spin)
		"Revive":
			add_text(content,"You fell to the spirit plague.")
			add_button(content,"Revive",func():game.revive(); close_page())
		"Trade":
			add_text(content,"Offline layout preview — trading requires server")
			var row := HBoxContainer.new()
			content.add_child(row)
			grid(row,48,8,game.items)
			grid(row,30,5)
			grid(row,30,5)
		"Shop":
			add_text(content,"General / Special / History  •  Preview")
			grid(content,50,10)
		"Market": add_text(content,"Buy / Sell / My Listings / History\nOnline market not connected (demo).")
		"Quest": add_text(content,"Main quest: Defeat spirits\nEXP: %d / 100\nSide / Daily / Completed preview"%game.xp)
		"Social": add_text(content,"Friends / Party / Guild\nOnline backend not connected.")
		"Ranking": add_text(content,"Level / Power / PvP / Combat range / Weapon / Guild\nOffline preview")
		"News": add_text(content,"News / Events / Updates\nv0.1: Offline village prototype")
		"Map": add_text(content,"Spirit Village • Safe Zone (26 × 26 m)\nFour gates lead to the hunting grounds.\nNormal → outer Elite → Boss\nPosition: %s"%str(game.player.position))
