extends CanvasLayer
var game: Node3D
var root: Control
var stats: Label
var player_status: Control
var status_name: Label
var status_level: Label
var status_hp: Label
var status_mp: Label
var status_exp: Label
var status_fill_clips: Array[Control] = []
var status_portrait: Node3D
var status_portrait_view: SubViewport
var status_portrait_male := true
const PLAYER_HUD = "res://assets/player_hud/"
const Catalog = preload("res://item_catalog.gd")
var item_dialog: AcceptDialog
var damage_overlays: Dictionary = {}
var auto_hunt_art: TextureRect

func update_auto_hunt_indicator(delta: float):
	if not is_instance_valid(auto_hunt_art): return
	auto_hunt_art.pivot_offset=auto_hunt_art.size*0.5
	if game.auto and game.started and game.hp>0 and not game.in_safe_zone():
		auto_hunt_art.rotation=fposmod(auto_hunt_art.rotation+delta*TAU/1.8,TAU)
	else:
		auto_hunt_art.rotation=0.0
var cooldown_labels: Array[Label] = []

func update_combat_cooldowns():
	for i in range(cooldown_labels.size()):
		var remaining: float=game.remaining_cooldown(i)
		var l := cooldown_labels[i]
		l.visible=remaining>0.05
		l.text="%.1f"%remaining

func add_damage_overlay(number: Label3D):
	var value := Label.new()
	value.text=number.text
	value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	value.z_index=5
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size",42 if number.get_meta("critical") else 32)
	value.add_theme_color_override("font_color",number.modulate)
	value.add_theme_color_override("font_outline_color",Color("111318"))
	value.add_theme_constant_override("outline_size",7)
	root.add_child(value)
	damage_overlays[number]=value
	number.tree_exiting.connect(func():damage_overlays.erase(number);value.queue_free())

func update_damage_overlays():
	for number in damage_overlays:
		var value: Label=damage_overlays[number]
		value.visible=not game.camera.is_position_behind(number.global_position)
		value.position=game.camera.unproject_position(number.global_position)-value.size*0.5
		value.modulate.a=number.modulate.a
var target_label: Label
var target_status: Control
var target_bar: Control
var target_fill: Control
var target_hp: Label
var target_portrait_art: TextureRect
var target_portrait_image: TextureRect
var target_view: SubViewport
var target_model: Node3D
var portrait_source_id := 0
var target_menu_button: Button
var target_menu_icon: TextureRect
var target_menu: Control
var target_actions: Array[Button]=[]
var target_notice: Label
var target_notice_time := 0.0
var demo_friends: Array[String]=[]
var demo_party: Array[String]=[]
var demo_guild: Array[String]=[]
var trade_partner := ""
var zone_label: Label
var camera_mode_button: Button
var minimap: Control
var panel: PanelContainer
var body: VBoxContainer
var chat: LineEdit
var joystick: Button
var joystick_knob: TextureRect
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
var settings_category := 0
var news_tab := 0
var gm_tab := 0
var gm_server_tab := 0
var gm_button: Button
var gm_notice: Label
const GM_PAGE=preload("res://gm_page.gd")
var social_tab := 0
var social_sub := 0
var social_split := 0
var trade_selected: Dictionary = {}
var trade_gold := 0
var market_tab := 0
var market_selected := -1
var market_listings: Array = []
var market_history: Array = []
var market_filter := ""
var market_sort := 0
var warp_selected := 0
const ONLINE_PAGES=preload("res://online_pages.gd")
var quest_tab := 0
var quest_selected := "main"
var tracked_quest := ""
var quest_tracker: Label
var quest_list_status: Dictionary = {}
var quest_detail_status: Label
var quest_detail_bar: ProgressBar
var quest_claim_button: Button
var quest_countdown: Label
const QUEST_PAGE = preload("res://quest_page.gd")
var news_selected := 0
var shop_tab := 0
var shop_category := 0
var shop_selected := -1
var ranking_tab := 0
var ranking_filter := 0
var shop_history: Array = []
var hud_defaults: Dictionary = {}
var editable_hud: Dictionary = {}
var editor_panel: PanelContainer
var editor_snapshot: Dictionary = {}
var editor_selected: Control
var editor_finger := -1
var editor_offset := Vector2.ZERO
var editor_size: HSlider
var editor_alpha: HSlider
var editor_title: Label
var editor_refresh := false
const UHD = "res://assets/uhd/"
const ACTION_ART = {
	"ATTACK":preload("res://assets/controls/actions/attack.png"),
	"SKILL 1":preload("res://assets/controls/actions/skill1.png"),
	"SKILL 2":preload("res://assets/controls/actions/skill2.png"),
	"SKILL 3":preload("res://assets/controls/actions/skill3.png"),
	"JUMP":preload("res://assets/controls/actions/jump.png"),
	"DASH":preload("res://assets/controls/actions/dash.png"),
	"LOOT":preload("res://assets/controls/actions/loot.png"),
	"AUTO":preload("res://assets/controls/actions/auto.png"),
	"MONSTER":preload("res://assets/controls/actions/monster.png"),
	"PLAYER":preload("res://assets/controls/actions/player.png"),
	"RUN":preload("res://assets/controls/actions/run.png"),
}
const INVENTORY_PAGES = ["Bag","Character","Storage","Skills"]
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
	# Old rectangular layouts must not override the new circular defaults.
	if int(config.get_value("ui","hud_layout",0))<2:
		for section in ["position","size","scale","opacity"]:
			if config.has_section(section): config.erase_section(section)
		config.set_value("ui","hud_layout",2)
		config.save("user://zmb.cfg")
	if int(config.get_value("ui","hud_layout",0))<3:
		for key in ["MENU","CAMERA"]:
			for section in ["position","size","scale"]:
				if config.has_section_key(section,key): config.erase_section_key(section,key)
		config.set_value("ui","hud_layout",3)
		config.save("user://zmb.cfg")
	if int(config.get_value("ui","hud_layout",0))<4:
		for key in ["STATUS","METER 0","METER 1"]:
			for section in ["position","size","scale","opacity"]:
				if config.has_section_key(section,key): config.erase_section_key(section,key)
		config.set_value("ui","hud_layout",4)
		config.save("user://zmb.cfg")
	if int(config.get_value("ui","hud_layout",0))<5:
		for key in ["TARGET","GM"]:
			for section in ["position","size","scale","opacity"]:
				if config.has_section_key(section,key): config.erase_section_key(section,key)
		config.set_value("ui","hud_layout",5)
		config.save("user://zmb.cfg")
	if int(config.get_value("ui","hud_layout",0))<6:
		for key in ["TARGET","ZONE"]:
			for section in ["position","size","scale","opacity"]:
				if config.has_section_key(section,key): config.erase_section_key(section,key)
		config.set_value("ui","hud_layout",6)
		config.save("user://zmb.cfg")
	lang=int(config.get_value("ui","lang",1))
	game.character_name=str(config.get_value("character","name","Warrior"))
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
	build_player_status()
	build_target_status()
	zone_label=label("",Vector2(420,106),Vector2(440,34))
	zone_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	zone_label.add_theme_font_size_override("font_size",21)
	var main_menu := make_button("MENU",Vector2(970,18),Vector2(120,48),func(): open_page("Menu"))
	main_menu.icon=preload("res://assets/menu_icons/menu.png")
	main_menu.add_theme_constant_override("icon_max_width",30)
	if game.gm_allowed():
		gm_button=make_button("GM",Vector2(855,18),Vector2(64,48),func():
			if is_instance_valid(game.target) and not game.is_demo_target(game.target): game.gm_target=game.target
			open_page("GM"))
		gm_button.icon=preload("res://assets/menu_icons/gm.png")
		gm_button.add_theme_font_size_override("font_size",12)
		gm_button.add_theme_constant_override("icon_max_width",24)
		gm_button.expand_icon=false
		gm_button.size=Vector2(64,48)
		gm_notice=label("",Vector2(380,142),Vector2(500,35))
		gm_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		gm_notice.add_theme_color_override("font_color",Color("f6d995"))
	minimap=preload("res://minimap.gd").new()
	minimap.game=game
	minimap.position=Vector2(1105,12)
	minimap.size=Vector2(155,155)
	root.add_child(minimap)
	var zoom_in := make_button("+",Vector2(1134,12),Vector2(32,32),func():minimap.change_zoom(0.5))
	var zoom_out := make_button("−",Vector2(1200,12),Vector2(32,32),func():minimap.change_zoom(-0.5))
	zoom_in.tooltip_text="Minimap zoom in"
	zoom_out.tooltip_text="Minimap zoom out"
	for zoom_button in [zoom_in,zoom_out]:
		zoom_button.remove_meta("round")
		for state in ["normal","hover","pressed","focus","disabled"]:
			zoom_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		zoom_button.add_theme_font_size_override("font_size",20)
	joystick=make_button("◉",Vector2(78,474),Vector2(220,220),func(): pass)
	joystick.add_theme_color_override("font_color",Color.TRANSPARENT)
	joystick.add_theme_color_override("font_hover_color",Color.TRANSPARENT)
	joystick.add_theme_color_override("font_pressed_color",Color.TRANSPARENT)
	for state in ["normal","hover","pressed","focus"]:
		joystick.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var joystick_base := TextureRect.new()
	joystick_base.texture=preload("res://assets/controls/joystick_base_gray.png")
	joystick_base.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	joystick_base.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_base.mouse_filter=Control.MOUSE_FILTER_IGNORE
	joystick.add_child(joystick_base)
	joystick_base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick_knob=TextureRect.new()
	joystick_knob.texture=preload("res://assets/controls/joystick_thumb_gray.png")
	joystick_knob.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	joystick_knob.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	joystick_knob.mouse_filter=Control.MOUSE_FILTER_IGNORE
	joystick_knob.size=Vector2(76,76)
	joystick.add_child(joystick_knob)
	joystick.gui_input.connect(_stick_event)
	make_button("ATTACK",Vector2(1124,580),Vector2(124,124),func(): game.attack(0))
	var skills := [Vector2(970,614),Vector2(1036,512),Vector2(1140,468)]
	for i in range(3):
		make_button("SKILL %d"%(i+1),skills[i],Vector2(88,88),func():game.attack(i+1))
	make_button("JUMP",Vector2(1094,368),Vector2(72,72),func():game.jump_requested=true)
	make_button("DASH",Vector2(1002,425),Vector2(72,72),func():game.request_dash())
	make_button("RUN",Vector2(940,535),Vector2(64,64),func():game.toggle_run())
	make_button("LOOT",Vector2(1014,80),Vector2(70,70),func():game.collect())
	make_button("AUTO",Vector2(1204,338),Vector2(70,70),func():
		if not game.in_safe_zone():
			game.auto=not game.auto
			if not game.auto: game.cancel_attack())
	make_button("MONSTER",Vector2(1120,270),Vector2(54,54),func():game.choose_target())
	make_button("PLAYER",Vector2(1200,270),Vector2(54,54),func():game.choose_player_target())
	make_button("HP",Vector2(888,634),Vector2(64,64),func():game.hp=minf(game.max_hp(),game.hp+35))
	make_button("MP",Vector2(815,640),Vector2(64,64),func():game.mp=minf(game.max_mp(),game.mp+35))
	game.set_camera_follow(bool(config.get_value("camera","follow",false)))
	camera_mode_button=make_button("CAMERA",Vector2(1118,224),Vector2(130,32),func():
		game.set_camera_follow(not game.camera_follow)
		config.set_value("camera","follow",game.camera_follow)
		config.save("user://zmb.cfg"))
	camera_mode_button.add_theme_font_size_override("font_size",13)
	chat=LineEdit.new()
	chat.placeholder_text="Chat • local demo"
	chat.position=Vector2(350,648)
	chat.size=Vector2(420,40)
	chat.modulate.a=0.35
	chat.focus_entered.connect(func(): chat.modulate.a=1)
	chat.focus_exited.connect(func(): chat.modulate.a=float(config.get_value("opacity","CHAT",0.35)))
	chat.text_submitted.connect(func(_s): chat.clear(); chat.release_focus())
	root.add_child(chat)
	for b in buttons: editable_hud[b.get_meta("hud_key")]=b
	editable_hud["STATUS"]=player_status
	editable_hud["TARGET"]=target_status
	editable_hud["ZONE"]=zone_label
	editable_hud["CHAT"]=chat
	editable_hud["MAP"]=minimap
	quest_tracker=label("",Vector2(22,172),Vector2(310,68))
	quest_tracker.mouse_filter=Control.MOUSE_FILTER_IGNORE
	quest_tracker.add_theme_font_size_override("font_size",16)
	editable_hud["QUEST TRACKER"]=quest_tracker
	for key in editable_hud:
		var c: Control=editable_hud[key]
		if not hud_defaults.has(key):
			hud_defaults[key]=[c.position,c.scale,c.modulate.a]
		c.position=config.get_value("position",key,c.position)
		c.scale=config.get_value("scale",key,c.scale)
		c.modulate.a=config.get_value("opacity",key,c.modulate.a)
	apply_settings()
	game.zoom=clampf(float(config.get_value("settings","zoom",10.0)),4.0,16.0)
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

func status_art(parent: Control, file: String, pos: Vector2, dimensions: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.texture=load(PLAYER_HUD+file)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_SCALE
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.position=pos
	art.size=dimensions
	return art

func status_text(parent: Control, pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_outline_color",Color("111318"))
	l.add_theme_constant_override("outline_size",4)
	parent.add_child(l)
	l.position=pos
	l.size=dimensions
	return l

func build_player_status():
	player_status=Control.new()
	player_status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(player_status)
	player_status.position=Vector2(18,14)
	player_status.size=Vector2(344,133)
	status_art(player_status,"02_nameplate.png",Vector2(77,0),Vector2(267,29))
	status_name=status_text(player_status,Vector2(94,0),Vector2(232,29),19)
	status_name.clip_text=true
	status_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status_name.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	for i in range(3):
		var p := Vector2(83,31+i*25)
		status_art(player_status,["04_bar_track.png","10_mp_track.png","11_exp_track.png"][i],p,Vector2(261,24))
		var clip := Control.new()
		clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
		clip.clip_contents=true
		player_status.add_child(clip)
		clip.position=p+Vector2(4,4)
		clip.size=Vector2(253,16)
		status_art(clip,["05_hp_fill.png","06_mp_fill.png","09_exp_fill.png"][i],Vector2.ZERO,Vector2(253,16))
		status_fill_clips.append(clip)
		var l := status_text(player_status,p,Vector2(261,24),15)
		if i==0: status_hp=l
		elif i==1: status_mp=l
		else: status_exp=l
	status_art(player_status,"01_portrait_frame.png",Vector2.ZERO,Vector2(92,92))
	var portrait := TextureRect.new()
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.position=Vector2(15,10)
	portrait.size=Vector2(62,68)
	player_status.add_child(portrait)
	status_portrait_view=SubViewport.new()
	status_portrait_view.size=Vector2i(124,136)
	status_portrait_view.own_world_3d=true
	status_portrait_view.transparent_bg=true
	status_portrait_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	portrait.add_child(status_portrait_view)
	portrait.texture=status_portrait_view.get_texture()
	status_portrait=game.player_visual.duplicate()
	status_portrait.position=Vector3.ZERO
	status_portrait.rotation=Vector3(0,PI,0)
	status_portrait_view.add_child(status_portrait)
	var cam := Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=0.88
	cam.position=Vector3(0,1.51,4)
	status_portrait_view.add_child(cam)
	cam.current=true
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-25,20,0)
	light.light_energy=1.6
	status_portrait_view.add_child(light)
	status_art(player_status,"03_level_badge.png",Vector2(15,69),Vector2(62,24))
	status_level=status_text(player_status,Vector2(15,69),Vector2(62,24),13)
	stats=status_text(player_status,Vector2(93,107),Vector2(250,22),13)
	stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT

func refresh_player_status():
	status_name.text=game.character_name
	status_level.text="LV %d"%game.level
	status_hp.text="HP  %d / %d"%[game.hp,game.max_hp()]
	status_mp.text="MP  %d / %d"%[game.mp,game.max_mp()]
	status_exp.text="EXP  %d / 100"%game.xp
	status_fill_clips[0].size.x=253.0*clampf(game.hp/game.max_hp(),0,1)
	status_fill_clips[1].size.x=253.0*clampf(game.mp/game.max_mp(),0,1)
	status_fill_clips[2].size.x=253.0*clampf(game.xp/100.0,0,1)
	stats.text="Gold %d   v0.1.47"%game.coins
	if status_portrait_male!=game.male:
		status_portrait_male=game.male
		status_portrait.scale=game.player_visual.scale
		status_portrait_view.render_target_update_mode=SubViewport.UPDATE_ONCE

func build_target_status():
	target_status=Control.new()
	target_status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(target_status)
	target_status.position=Vector2(430,12)
	target_status.size=Vector2(410,113)
	target_portrait_art=status_art(target_status,"target_normal_ring.png",Vector2.ZERO,Vector2(72,72))
	target_portrait_image=TextureRect.new()
	target_portrait_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	target_portrait_image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_status.add_child(target_portrait_image)
	target_portrait_image.position=Vector2(12,7)
	target_portrait_image.size=Vector2(48,53)
	target_view=SubViewport.new()
	target_view.size=Vector2i(96,106)
	target_view.own_world_3d=true
	target_view.transparent_bg=true
	target_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	target_portrait_image.add_child(target_view)
	target_portrait_image.texture=target_view.get_texture()
	var cam := Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=0.88
	cam.position=Vector3(0,1.51,4)
	target_view.add_child(cam)
	cam.current=true
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-25,20,0)
	light.light_energy=1.6
	target_view.add_child(light)
	target_label=status_text(target_status,Vector2(75,0),Vector2(330,29),17)
	target_bar=Control.new()
	target_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_status.add_child(target_bar)
	target_bar.position=Vector2(75,29)
	target_bar.size=Vector2(330,28)
	status_art(target_bar,"07_target_track.png",Vector2.ZERO,Vector2(330,28))
	target_fill=Control.new()
	target_fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_fill.clip_contents=true
	target_bar.add_child(target_fill)
	target_fill.position=Vector2(20,6)
	target_fill.size=Vector2(290,16)
	status_art(target_fill,"target_hp_fill.png",Vector2.ZERO,Vector2(290,16))
	target_hp=status_text(target_bar,Vector2.ZERO,Vector2(330,28),14)
	target_bar.hide()
	target_menu_button=target_action_button(target_status,"",Vector2(17,74),Vector2(38,38),func():target_menu.visible=not target_menu.visible)
	for state in ["normal","hover","pressed","focus","disabled"]:
		target_menu_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	target_menu_icon=status_art(target_menu_button,"08_target_menu.png",Vector2.ZERO,Vector2(38,38))
	target_menu_icon.pivot_offset=Vector2(19,19)
	target_menu_button.hide()
	target_menu=Control.new()
	target_menu.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_status.add_child(target_menu)
	target_menu.position=Vector2(0,116)
	target_menu.size=Vector2(174,185)
	target_menu.z_index=5
	for i in range(5):
		var action:=i
		target_action_button(target_menu,"",Vector2(0,i*37),Vector2(174,35),func():perform_target_action(action))
	target_menu.hide()
	target_notice=status_text(target_status,Vector2(0,128),Vector2(410,30),15)
	target_notice.hide()

func target_action_button(parent: Control, title: String, pos: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var b:=Button.new()
	b.text=title
	b.position=pos
	b.size=dimensions
	b.add_theme_font_size_override("font_size",15)
	b.focus_mode=Control.FOCUS_NONE
	parent.add_child(b)
	b.pressed.connect(action)
	touch_actions[b]=action
	target_actions.append(b)
	return b

func perform_target_action(action: int):
	target_menu.hide()
	if not game.is_demo_target(game.target): return
	var who:=str(game.target.get_meta("display_name"))
	var message: String
	match action:
		0:
			if not demo_friends.has(who): demo_friends.append(who)
			message=localized("เพิ่มเพื่อนจำลองแล้ว","Demo friend added","已添加测试好友")
		1:
			if not demo_party.has(who): demo_party.append(who)
			message=localized("เชิญปาร์ตี้จำลองแล้ว","Demo party invitation","已模拟组队邀请")
		2:
			if not demo_guild.has(who): demo_guild.append(who)
			message=localized("เชิญกิลด์จำลองแล้ว","Demo guild invitation","已模拟公会邀请")
		3:
			trade_partner=who
			trade_selected.clear()
			trade_gold=0
			open_page("Trade")
			return
		4:
			game.toggle_player_follow()
			message=localized("กำลังเดินตาม","Following","正在跟随") if is_instance_valid(game.follow_player) else localized("หยุดเดินตาม","Follow stopped","已停止跟随")
	target_notice.text=message+" • "+who
	target_notice_time=3.0
	target_notice.show()

func refresh_target_status(safe: bool):
	var n: Node3D=game.target
	var valid:=is_instance_valid(n)
	var show_player: bool=valid and game.is_demo_target(n)
	target_portrait_art.visible=valid or is_instance_valid(editor_panel)
	target_portrait_image.visible=valid
	target_menu_button.visible=show_player
	if not show_player: target_menu.hide()
	if valid and portrait_source_id!=n.get_instance_id():
		target_portrait_art.texture=load(PLAYER_HUD+["target_normal_ring.png","target_elite_ring.png","target_boss_ring.png"][clampi(int(n.get_meta("tier",0)),0,2)])
		portrait_source_id=n.get_instance_id()
		target_menu.hide()
		if is_instance_valid(target_model): target_model.queue_free()
		target_model=n.get_child(0).duplicate() as Node3D
		target_model.position=Vector3.ZERO
		target_model.rotation=Vector3(0,PI,0)
		target_view.add_child(target_model)
		target_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	elif not valid: portrait_source_id=0
	if show_player:
		var captions: Array[String]=[localized("เพิ่มเพื่อน","Add friend","添加好友"),localized("ชวนปาร์ตี้","Invite party","邀请组队"),localized("ชวนกิลด์","Invite guild","邀请公会"),localized("แลกเปลี่ยน","Trade","交易"),localized("หยุดเดินตาม","Stop following","停止跟随") if game.follow_player==n else localized("เดินตาม","Follow","跟随")]
		for i in range(5): target_actions[i+1].text=captions[i]
		target_menu_icon.rotation=PI if target_menu.visible else 0.0
		target_menu_button.tooltip_text=localized("เมนูเป้าหมาย","Target actions","目标菜单")
	if is_instance_valid(n):
		var max_hp: float=float(n.get_meta("max_hp",40+80*int(n.get_meta("tier",0))))
		var health: float=clampf(float(n.get_meta("hp",0)),0,max_hp)
		target_label.text=str(n.get_meta("display_name",""))+" • LV 1" if game.is_demo_target(n) else ["Normal","Elite","Boss"][int(n.get_meta("tier",0))]+" • LV 1"
		target_fill.size.x=290.0*health/maxf(1,max_hp)
		target_hp.text="HP %d / %d"%[health,max_hp]
		target_bar.show()
	else:
		target_bar.visible=is_instance_valid(editor_panel)
		if target_bar.visible:
			target_fill.size.x=290
			target_hp.text="HP 100 / 100"
		target_label.text=localized("หมู่บ้านวิญญาณ","Spirit Village","灵魂村") if safe else ("AUTO HUNT" if game.auto else "ZMB • OFFLINE DEMO")

func make_button(t:String,p:Vector2,s:Vector2,action:Callable) -> Button:
	var b := Button.new()
	b.text=t
	hud_defaults[t]=[p,Vector2.ONE,0.82]
	b.set_meta("hud_key",t)
	b.position=config.get_value("position",t,p)
	b.size=config.get_value("size",t,s)
	b.scale=config.get_value("scale",t,Vector2.ONE)
	b.modulate.a=config.get_value("opacity",t,0.82)
	if t in ["MENU","GM"]:
		var silver := StyleBoxTexture.new()
		silver.texture=preload("res://assets/menu_icons/menu_button_silver.png")
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			silver.set_texture_margin(side,5)
			silver.set_content_margin(side,5)
		var hover := silver.duplicate() as StyleBoxTexture
		hover.modulate_color=Color(1.25,1.25,1.25)
		var pressed := silver.duplicate() as StyleBoxTexture
		pressed.modulate_color=Color(0.75,0.75,0.75)
		b.add_theme_stylebox_override("normal",silver)
		b.add_theme_stylebox_override("hover",hover)
		b.add_theme_stylebox_override("pressed",pressed)
		b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if t not in ["MENU","CAMERA","GM"]:
		b.set_meta("round",true)
		var round_style := StyleBoxFlat.new()
		round_style.bg_color=Color("252a2e99")
		round_style.border_color=Color("b5b9bd")
		round_style.set_border_width_all(2)
		round_style.set_corner_radius_all(int(s.x/2))
		round_style.set_content_margin_all(0)
		b.add_theme_stylebox_override("normal",round_style)
		var pressed_style := round_style.duplicate() as StyleBoxFlat
		pressed_style.bg_color=Color("6e3039bb")
		b.add_theme_stylebox_override("pressed",pressed_style)
		b.add_theme_stylebox_override("hover",round_style)
		b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		b.add_theme_font_size_override("font_size",12 if t in ["MONSTER","PLAYER"] else 16)
		b.clip_text=true
		b.set_deferred("size",config.get_value("size",t,s))
	if ACTION_ART.has(t):
		# Leave the original Button and key intact for input, settings and tests.
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color","font_disabled_color"]:
			b.add_theme_color_override(state,Color.TRANSPARENT)
		var art := TextureRect.new()
		art.texture=ACTION_ART[t]
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.offset_left=5
		art.offset_top=5
		art.offset_right=-5
		art.offset_bottom=-5
		if t=="AUTO": auto_hunt_art=art
		b.tooltip_text=t
	b.pressed.connect(action)
	if t=="ATTACK" or t.begins_with("SKILL "):
		var timer := Label.new()
		timer.mouse_filter=Control.MOUSE_FILTER_IGNORE
		timer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		timer.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		timer.add_theme_font_size_override("font_size",24)
		timer.add_theme_color_override("font_outline_color",Color("111318"))
		timer.add_theme_constant_override("outline_size",7)
		timer.hide()
		b.add_child(timer)
		timer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cooldown_labels.append(timer)
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
	game.stick = ((pos - rect.get_center()) / maxf(1.0, minf(rect.size.x, rect.size.y) * 0.31)).limit_length()

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
	var hit_buttons: Array[Button]=buttons.duplicate()
	hit_buttons.append_array(target_actions)
	for i in range(hit_buttons.size()-1, -1, -1):
		var button := hit_buttons[i]
		if not button.is_visible_in_tree() or button.disabled or not button.get_global_rect().has_point(pos):
			continue
		if button.get_meta("round",false):
			var rect := button.get_global_rect()
			if ((pos-rect.get_center())/(rect.size*0.5)).length()>1.0: continue
		captured_touches[index] = button
		if button == joystick:
			if joystick_finger == -1:
				joystick_finger = index
				_set_touch_stick(pos)
		else:
			var action: Callable = touch_actions[button]
			action.call()
		return true
	if target_menu.visible: target_menu.hide()
	if not chat.get_global_rect().has_point(pos): game.select_target_at(pos)
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

func _camera_touch_drag(index: int, position: Vector2):
	if camera_touches.size()==1:
		# Derive the delta from this finger's own last position, not a
		# platform-reported relative delta that may jump between touches.
		var relative: Vector2=position-camera_touches[index]
		camera_touches[index]=position
		game.rotate_camera(relative)
		return
	# Only fingers that started on the world participate, never joystick or action buttons.
	var keys := camera_touches.keys()
	var a: int=keys[0]
	var b: int=keys[1]
	var before: float=camera_touches[a].distance_to(camera_touches[b])
	camera_touches[index]=position
	if index!=a and index!=b: return
	var after: float=camera_touches[a].distance_to(camera_touches[b])
	if before>8.0 and after>8.0:
		game.zoom=clampf(game.zoom*pow(before/after,game.zoom_sensitivity),4.0,16.0)

func _modal_scroll_input(event: InputEvent) -> bool:
	if not is_instance_valid(modal_scroll): return false
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			# Sliders own their touches; a vertical scroll must not steal them.
			for child in modal_scroll.find_children("*","HSlider",true,false):
				if child.get_global_rect().has_point(event.position): return false
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
	if is_instance_valid(item_dialog) and item_dialog.visible: return
	if is_instance_valid(editor_panel):
		if editor_input(event): get_viewport().set_input_as_handled()
		return
	# Godot's mouse emulation represents only one finger. HUD controls use
	# actual touch indices instead, while popup menus still use mouse emulation.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseButton and event.pressed: swallow_scroll_release=false
		if scroll_dragged or swallow_scroll_release:
			if event is InputEventMouseButton and not event.pressed: swallow_scroll_release=false
			get_viewport().set_input_as_handled()
			return
		if not captured_touches.is_empty() or not camera_touches.is_empty() or (game.started and not is_instance_valid(panel) and not chat.get_global_rect().has_point(event.position) and not chat.has_focus()):
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
		elif game.started and not is_instance_valid(panel) and not chat.get_global_rect().has_point(event.position):
			camera_touches[event.index]=event.position
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _touch_move(event.index, event.position): get_viewport().set_input_as_handled()
		elif camera_touches.has(event.index):
			_camera_touch_drag(event.index,event.position)
			get_viewport().set_input_as_handled()

func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(game):
		_reset_touches()

func _process(delta):
	if not is_instance_valid(stats): return
	update_auto_hunt_indicator(delta)
	update_combat_cooldowns()
	update_damage_overlays()
	if is_instance_valid(gm_button):
		gm_button.visible=game.gm_allowed()
		gm_notice.text=game.gm_announcement if game.gm_allowed() else ""
	if selected_page=="Quest": update_quest_ui()
	if is_instance_valid(quest_tracker):
		quest_tracker.visible=not tracked_quest.is_empty() or is_instance_valid(editor_panel)
		if tracked_quest.is_empty():
			quest_tracker.text=trn("Quest")
		else:
			quest_tracker.text=QUEST_PAGE.title(self,tracked_quest)+"\n%d / %d"%[mini(game.quest_progress(tracked_quest),game.quest_goal(tracked_quest)),game.quest_goal(tracked_quest)]
	joystick_knob.position=(joystick.size-joystick_knob.size)*0.5+game.stick*(joystick.size.x-joystick_knob.size.x)*0.5
	if selected_page=="Character": refresh_character_details()
	refresh_player_status()
	camera_mode_button.text=(["กล้อง: ตามหลัง","CAM: FOLLOW","镜头：跟随"][lang] if game.camera_follow else ["กล้อง: อิสระ","CAM: FREE","镜头：自由"][lang])
	var safe: bool = game.in_safe_zone()
	zone_label.text=(["เขตปลอดภัย • ฟื้นฟู HP/MP","SAFE ZONE • HP/MP recovery","安全区 • 恢复生命与法力"][lang] if safe else ["เขตล่ามอนสเตอร์ • LV 1+","HUNTING ZONE • LV 1+","狩猎区 • LV 1+"][lang])
	zone_label.modulate=Color("a7f2bd") if safe else Color("ffaf83")
	refresh_target_status(safe)
	if target_notice_time>0:
		target_notice_time-=delta
		if target_notice_time<=0: target_notice.hide()
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
		var d := {"version":"0.1.47","ready":true,"started":game.started,"safe":safe,"hp":game.hp,"mp":game.mp,"zoom":game.zoom,"camera_follow":game.camera_follow,"pitch":game.pitch,"yaw":game.yaw,"facing":game.player_visual.rotation.y,"page":selected_page,"menu_items":menu_rects,"scroll_rect":_web_rect(modal_scroll) if is_instance_valid(modal_scroll) else [],"scroll_value":modal_scroll.scroll_vertical if is_instance_valid(modal_scroll) else 0,"controls":controls,"stick":[game.stick.x,game.stick.y],"touches":captured_touches.size(),"position":[game.player.position.x,game.player.position.y,game.player.position.z],"velocity":[game.player.velocity.x,game.player.velocity.y,game.player.velocity.z]}
		var payload := JSON.stringify(d)
		if browser_window != null:
			browser_window.zmbDiagnosticsJSON = payload

func close_page():
	character_values.clear()
	quest_list_status.clear()
	quest_detail_status=null
	quest_detail_bar=null
	quest_claim_button=null
	quest_countdown=null
	if is_instance_valid(panel): panel.queue_free()
	panel=null
	close_button=null
	modal_scroll=null
	menu_items.clear()
	scroll_finger=-1
	scroll_dragged=false
	selected_page=""

func update_quest_ui():
	for id in quest_list_status:
		var progress: int=mini(game.quest_progress(id),game.quest_goal(id))
		var status: String=localized("รับแล้ว","Claimed","已领取") if game.is_quest_claimed(id) else (localized("พร้อมรับรางวัล","Ready to claim","可领取") if progress>=game.quest_goal(id) else localized("กำลังดำเนินการ","In progress","进行中"))
		quest_list_status[id].text="%s  •  %d / %d"%[status,progress,game.quest_goal(id)]
	if is_instance_valid(quest_detail_bar):
		var current: int=mini(game.quest_progress(quest_selected),game.quest_goal(quest_selected))
		quest_detail_bar.value=current
		quest_detail_status.text=localized("ความคืบหน้า","Progress","进度")+"  %d / %d"%[current,game.quest_goal(quest_selected)]
		if is_instance_valid(quest_claim_button):
			quest_claim_button.disabled=current<game.quest_goal(quest_selected) or game.is_quest_claimed(quest_selected)
	if is_instance_valid(quest_countdown):
		var remaining: int=86400-int(Time.get_unix_time_from_system())%86400
		quest_countdown.text=localized("รีเซ็ตใน","Resets in","重置倒计时")+"  "+format_playtime(remaining)

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

var bag_page := 0

func inventory_grid(parent: Node, count: int, columns: int, contents: Array=[], offset: int=0, slot_size: Vector2=Vector2(56,56), locked: bool=false):
	var g := GridContainer.new()
	g.columns=columns
	g.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation",5)
	g.add_theme_constant_override("v_separation",5)
	parent.add_child(g)
	for i in range(count):
		var filled := i<contents.size()
		var b := inventory_slot(g,"◆" if filled else "",slot_size,filled)
		if locked:
			b.disabled=true
			b.modulate=Color("666666")
		if filled:
			var id: String=contents[i]
			var data := Catalog.describe(id)
			b.text=data.icon
			b.modulate=data.color
			b.tooltip_text=id
			if selected_page in ["Bag","Storage"]: b.pressed.connect(func(): show_item_details(id,offset+i))
	return g

func bag_page_buttons(parent: Node, page: String, show_locked: bool=true):
	var pages:=HBoxContainer.new()
	pages.alignment=BoxContainer.ALIGNMENT_CENTER
	parent.add_child(pages)
	var unlocked: int=game.bag_capacity()/50
	for i in range(6 if show_locked else unlocked):
		var title:=localized("หน้า%d","Page %d","第%d页")%(i+1)
		var b: Button=add_button(pages,title,func():bag_page=i;open_page(page))
		b.custom_minimum_size=Vector2(68,32)
		b.add_theme_font_size_override("font_size",13)
		if bag_page==i:
			var active:=StyleBoxFlat.new()
			active.bg_color=Color("75232c")
			active.set_corner_radius_all(6)
			b.add_theme_stylebox_override("normal",active)

func build_bag_contents(parent: Node, page: String):
	var capacity: int=game.bag_capacity()
	bag_page=clampi(bag_page,0,5)
	var offset:=bag_page*50
	var locked:=offset>=capacity
	add_text(parent,localized("กระเป๋า","Inventory","背包")+"  %d / %d  (300 max)"%[game.items.size(),capacity])
	inventory_grid(parent,50,10,[] if locked else game.items.slice(offset,offset+50),offset,Vector2(46,46),locked)
	bag_page_buttons(parent,page)
	if locked:
		var next: int=capacity/50
		add_text(parent,localized("ปลดล็อกหน้าถัดไป: เลเวล %d หรือออนไลน์สะสม %d ชม.","Next unlock: LV %d or %d online hours","下一页解锁：等级 %d 或累计在线 %d 小时")%[game.BAG_UNLOCK_LEVELS[next],game.BAG_UNLOCK_HOURS[next]])
		var unlock: Button=add_button(parent,localized("ซื้อไอเทมขยายกระเป๋า","Buy bag expansion item","购买背包扩展道具")+" • %d G"%game.BAG_UNLOCK_PRICE,func():
			if game.buy_bag_unlock(): open_page(page))
		unlock.disabled=game.coins<game.BAG_UNLOCK_PRICE
	add_text(parent,localized("เงิน","Gold","金币")+"  %d"%game.coins)

func show_item_details(id: String, index: int=-1, equipped_slot: String=""):
	if is_instance_valid(item_dialog): item_dialog.queue_free()
	var data := Catalog.describe(id)
	var dialog := AcceptDialog.new()
	item_dialog=dialog
	dialog.title=id
	dialog.dialog_text="%s  •  %s\nATK +%d   DEF +%d\nHP +%d   MP +%d   CRIT +%.0f%%\n%s: %d"%[data.icon,data.rarity,data.attack,data.defense,data.hp,data.mp,data.crit*100,localized("จำนวนในกระเป๋า","In bag","背包数量"),game.items.count(id)]
	dialog.ok_button_text=localized("ปิด","Close","关闭")
	root.add_child(dialog)
	if not equipped_slot.is_empty(): dialog.add_button(localized("ถอด","Unequip","卸下"),true,"unequip")
	else:
		for slot in data.slots: dialog.add_button(localized("สวมใส่","Equip","装备")+" • "+slot,true,slot)
	dialog.custom_action.connect(func(action):
		var success: bool=game.unequip_item(equipped_slot) if action=="unequip" else (index<game.items.size() and game.items[index]==id and game.equip_item(index,action))
		if success: dialog.queue_free();open_page("Bag"))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(440,230))

func equipment_slot(parent: Node, title: String, slot: String, dimensions: Vector2):
	var id: String=game.equipment.get(slot,"")
	var b := inventory_slot(parent,title,dimensions,not id.is_empty())
	b.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	b.clip_text=true
	b.add_theme_font_size_override("font_size",10 if dimensions.x<55 else 11)
	b.set_meta("equipment_slot",slot)
	if not id.is_empty():
		var data := Catalog.describe(id)
		b.text=data.icon+" "+title
		b.modulate=data.color
		b.tooltip_text=id
		b.pressed.connect(func():show_item_details(id,-1,slot))

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
	row.size_flags_vertical=Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation",4)
	row.add_child(left)
	var titles := [localized("ศีรษะ","Head","头部"),localized("เสื้อ","Armor","护甲"),localized("ถุงมือ","Gloves","手套"),localized("กางเกง","Legs","裤子"),localized("รองเท้า","Boots","鞋子")]
	for i in range(5): equipment_slot(left,titles[i],Catalog.SLOTS[i],Vector2(64,64))
	character_preview(row)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation",4)
	row.add_child(right)
	titles=[localized("อาวุธหลัก","Main weapon","主武器"),localized("อาวุธรอง","Off hand","副武器"),localized("สัตว์เก็บของ","Loot pet","拾取宠物")]
	for i in range(3): equipment_slot(right,titles[i],Catalog.SLOTS[i+5],Vector2(64,64))
	var accessories := HBoxContainer.new()
	accessories.alignment=BoxContainer.ALIGNMENT_CENTER
	accessories.add_theme_constant_override("separation",24)
	parent.add_child(accessories)
	titles=[localized("กำไล","Bracelet","手镯"),localized("แหวน","Ring","戒指"),localized("สร้อย","Necklace","项链"),localized("แหวน","Ring","戒指"),localized("กำไล","Bracelet","手镯")]
	for i in range(5): equipment_slot(accessories,titles[i],Catalog.SLOTS[i+8],Vector2(48,48))

func format_playtime(seconds: int) -> String:
	return "%02d:%02d:%02d"%[int(seconds/3600.0),int(seconds/60.0)%60,seconds%60]

func build_character_details(parent: VBoxContainer):
	parent.add_theme_constant_override("separation",3)
	var spacer := Control.new()
	spacer.custom_minimum_size.y=8
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
		"name":localized("ชื่อตัวละคร","Character name","角色名称"),
		"level":localized("เลเวล","Level","等级"),
		"gender":localized("เพศ","Gender","性别"),
		"weapon":localized("สายอาวุธ","Weapon type","武器类型"),
		"hp":localized("พลังชีวิต","Health","生命值"),
		"mp":localized("พลังเวท","Mana","法力值"),
		"xp":localized("ค่าประสบการณ์","Experience","经验值"),
		"attack":localized("พลังโจมตีพื้นฐาน","Base attack","基础攻击"),
		"defense":localized("พลังป้องกัน","Defense","防御"),
		"crit":localized("โอกาสคริติคอล","Critical chance","暴击率"),
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
		name_label.add_theme_font_size_override("font_size",12)
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		details.add_child(name_label)
		var value := Label.new()
		value.add_theme_font_size_override("font_size",12)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		if key=="name": value.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
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
		"name":game.character_name,
		"level":str(game.level),
		"gender":localized("ชาย","Male","男") if game.male else localized("หญิง","Female","女"),
		"weapon":[localized("ดาบ","Sword","剑"),localized("ทวน","Spear","枪"),localized("ปืน","Gun","火枪")][game.weapon],
		"hp":"%d / %d"%[game.hp,game.max_hp()],
		"mp":"%d / %d"%[game.mp,game.max_mp()],
		"xp":"%d / 100"%game.xp,
		"attack":str(game.attack_power()),
		"defense":str(game.defense_power()),
		"crit":"%.0f%%"%(clampf(game.critical_chance+game.bonus("crit"),0,1)*100),
		"range":"%.1f m"%[2.7,5.5,12.0][game.weapon],
		"attack_speed":"%.2f / s"%(game.gm_attack_multiplier/0.45),
		"movement":"%.1f m/s"%(18.0 if game.dash_time>0 else (8.0 if game.run_mode else 4.5)*game.gm_move_multiplier),
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
			build_bag_contents(right,page)
		"Storage":
			add_text(left,localized("คลัง (ตัวอย่าง)","Storage (preview)","仓库（预览）"))
			inventory_grid(left,48,8)
			build_bag_contents(right,page)
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
	panel.position=Vector2(55,82)
	panel.size=Vector2(1040,112)
	panel.z_index=20
	var frame := StyleBoxTexture.new()
	frame.texture=preload("res://assets/menu_icons/quick_menu_silver.png")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		frame.set_texture_margin(side,12)
		frame.set_content_margin(side,0)
	panel.add_theme_stylebox_override("panel",frame)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.layout_direction=Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation",0)
	margin.add_child(row)
	var menu_font := FontVariation.new()
	menu_font.base_font=root.theme.default_font
	menu_font.variation_embolden=0.45
	var idle := StyleBoxEmpty.new()
	var highlight := StyleBoxFlat.new()
	highlight.bg_color=Color("a7adb122")
	highlight.set_corner_radius_all(6)
	for key in MENU_PAGES:
		var b := Button.new()
		b.text=trn(key)
		b.tooltip_text=trn(key)
		b.custom_minimum_size=Vector2(82,94)
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.clip_text=true
		b.icon=load("res://assets/menu_icons/"+key.to_lower()+".png")
		b.add_theme_stylebox_override("normal",idle)
		b.add_theme_stylebox_override("focus",idle)
		b.add_theme_stylebox_override("hover",highlight)
		b.add_theme_stylebox_override("pressed",highlight)
		# Keep the native button for touch, keyboard and accessibility; render
		# its icon and caption together as one vertically centered stack.
		for color_key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]:
			b.add_theme_color_override(color_key,Color.TRANSPARENT)
		b.add_theme_constant_override("icon_max_width",48)
		var stack := VBoxContainer.new()
		stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.alignment=BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation",2)
		b.add_child(stack)
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var art := TextureRect.new()
		art.texture=b.icon
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size=Vector2(54,54)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.add_child(art)
		var caption := Label.new()
		caption.text=b.text
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_override("font",menu_font)
		caption.add_theme_font_size_override("font_size",16)
		caption.add_theme_color_override("font_color",Color("e8e9ec"))
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.add_child(caption)
		b.pressed.connect(func():open_page(key))
		row.add_child(b)
		menu_items[key]=b

func save_setting(key: String, value):
	config.set_value("settings",key,value)
	config.save("user://zmb.cfg")
	apply_settings()

func apply_settings():
	Engine.max_fps=int(config.get_value("settings","fps",60))
	get_viewport().scaling_3d_scale=float(config.get_value("settings","quality",1.0))
	game.sun_light.shadow_enabled=bool(config.get_value("settings","shadows",true))
	game.camera_sensitivity=float(config.get_value("settings","camera_sensitivity",100))/100.0
	game.zoom_sensitivity=float(config.get_value("settings","zoom_sensitivity",100))/100.0
	game.stick_deadzone=float(config.get_value("settings","deadzone",6))/100.0
	game.auto_hp_threshold=int(config.get_value("settings","auto_hp",0))
	game.auto_mp_threshold=int(config.get_value("settings","auto_mp",0))
	game.auto_loot=bool(config.get_value("settings","auto_loot",true))
	game.nearest_target_only=bool(config.get_value("settings","nearest",false))
	for bus in ["Music","Combat","System"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
		var idx := AudioServer.get_bus_index(bus)
		var volume := float(config.get_value("settings",bus,100))/100.0
		AudioServer.set_bus_mute(idx,volume<=0)
		AudioServer.set_bus_volume_db(idx,linear_to_db(maxf(volume,0.001)))

func setting_slider(parent: Node, title: String, key: String, low: float, high: float, initial: float, step: float=1.0):
	var row := HBoxContainer.new()
	parent.add_child(row)
	var caption := Label.new()
	caption.text=title
	caption.custom_minimum_size.x=230
	row.add_child(caption)
	var slider := HSlider.new()
	slider.min_value=low
	slider.max_value=high
	slider.step=step
	slider.value=float(config.get_value("settings",key,initial))
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y=46
	row.add_child(slider)
	var value := Label.new()
	value.custom_minimum_size.x=64
	value.text=str(slider.value)
	row.add_child(value)
	slider.value_changed.connect(func(v): value.text=str(v);save_setting(key,v))

func setting_toggle(parent: Node, title: String, key: String, initial: bool):
	var check := CheckButton.new()
	check.text=title
	check.button_pressed=bool(config.get_value("settings",key,initial))
	check.custom_minimum_size.y=46
	parent.add_child(check)
	check.toggled.connect(func(v):save_setting(key,v))

func setting_choice(parent: Node,title: String,key: String,labels: Array,values: Array,initial):
	add_text(parent,title)
	var row := HBoxContainer.new()
	parent.add_child(row)
	var group := ButtonGroup.new()
	for i in range(labels.size()):
		var b: Button=add_button(row,labels[i],func():save_setting(key,values[i]))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.toggle_mode=true
		b.button_group=group
		b.button_pressed=config.get_value("settings",key,initial)==values[i]

func build_settings(parent: VBoxContainer):
	var horizontal := HBoxContainer.new()
	horizontal.size_flags_vertical=Control.SIZE_EXPAND_FILL
	horizontal.add_theme_constant_override("separation",16)
	parent.add_child(horizontal)
	var nav := VBoxContainer.new()
	nav.custom_minimum_size.x=255
	nav.add_theme_constant_override("separation",7)
	horizontal.add_child(nav)
	var categories := [localized("กราฟิก","Graphics","画面"),localized("เสียง","Audio","声音"),localized("การควบคุม","Controls","控制"),localized("ปรับแต่ง HUD","HUD Editor","界面编辑"),localized("การต่อสู้","Combat","战斗"),localized("ภาษา","Language","语言"),localized("บัญชีผู้เล่น","Account","账号")]
	for i in range(categories.size()):
		var b: Button=add_button(nav,categories[i],func():settings_category=i;open_page("Settings"))
		b.custom_minimum_size.y=52
		if i==settings_category: b.add_theme_color_override("font_color",Color("ff9c8e"))
	horizontal.add_child(VSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone=12
	horizontal.add_child(scroll)
	modal_scroll=scroll
	var content := VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	add_text(content,categories[settings_category])
	content.add_child(HSeparator.new())
	match settings_category:
		0:
			setting_choice(content,localized("คุณภาพภาพ","Quality","画质"),"quality",[localized("ต่ำ","Low","低"),localized("กลาง","Medium","中"),localized("สูง","High","高")],[0.6,0.8,1.0],1.0)
			setting_choice(content,"FPS","fps",["30","60","90","120"],[30,60,90,120],60)
			setting_toggle(content,localized("เงา","Shadows","阴影"),"shadows",true)
			setting_toggle(content,localized("เอฟเฟกต์ (เตรียมไว้)","Effects (reserved)","特效（预留）"),"effects",true)
			add_text(content,localized("FPS จริงขึ้นกับอุปกรณ์","Actual FPS depends on device","实际帧率取决于设备"))
		1:
			setting_slider(content,localized("เพลงพื้นหลัง","Music","音乐"),"Music",0,100,100)
			setting_slider(content,localized("เสียงต่อสู้","Combat sounds","战斗音效"),"Combat",0,100,100)
			setting_slider(content,localized("เสียงระบบ","System sounds","系统音效"),"System",0,100,100)
			add_text(content,localized("บันทึกค่าพร้อมรองรับเสียงในอนาคต","Saved for future audio assets","设置将用于未来音频"))
		2:
			setting_slider(content,localized("ความไวกล้อง","Camera sensitivity","镜头灵敏度"),"camera_sensitivity",10,200,100)
			setting_slider(content,localized("ความไวซูม","Zoom sensitivity","缩放灵敏度"),"zoom_sensitivity",10,200,100)
			setting_slider(content,localized("ระยะนิ่งจอย (%)","Joystick deadzone (%)","摇杆死区 (%)"),"deadzone",0,30,6)
			add_text(content,localized("ระยะกล้อง","Camera distance","镜头距离"))
			var zoom_slider := HSlider.new()
			zoom_slider.min_value=4
			zoom_slider.max_value=16
			zoom_slider.step=0.1
			zoom_slider.value=game.zoom
			zoom_slider.custom_minimum_size.y=44
			zoom_slider.value_changed.connect(func(v):game.zoom=v;save_setting("zoom",v))
			content.add_child(zoom_slider)
		3:
			add_text(content,localized("ลากปุ่มบนหน้าจอจริง ปรับขนาดและความโปร่งใสแยกกัน","Drag each HUD element; adjust size and opacity","拖动界面元素并调整大小和透明度"))
			add_button(content,localized("เข้าสู่โหมดปรับแต่ง HUD","Open HUD Editor","编辑界面"),start_editor)
		4:
			var auto_check := CheckButton.new()
			auto_check.text="Auto Hunt"
			auto_check.button_pressed=game.auto
			auto_check.toggled.connect(func(v):
				game.auto=v and not game.in_safe_zone()
				if not game.auto: game.cancel_attack())
			content.add_child(auto_check)
			setting_toggle(content,localized("เก็บของอัตโนมัติขณะ Auto Hunt","Auto loot while hunting","自动拾取"),"auto_loot",true)
			setting_toggle(content,localized("เลือกเป้าหมายใกล้สุดเสมอ","Always select nearest target","优先最近目标"),"nearest",false)
			setting_slider(content,localized("ใช้ยา HP (%), 0 = ปิด","Auto HP (%), 0 = off","自动生命药 (%)"),"auto_hp",0,100,0)
			setting_slider(content,localized("ใช้ยา MP (%), 0 = ปิด","Auto MP (%), 0 = off","自动法力药 (%)"),"auto_mp",0,100,0)
		5:
			for i in range(3):
				var b: Button=add_button(content,["ไทย","English","简体中文"][i],func():lang=i;config.set_value("ui","lang",lang);config.save("user://zmb.cfg");open_page("Settings"))
				if i==lang: b.add_theme_color_override("font_color",Color("ff9c8e"))
		6:
			add_text(content,localized("บัญชีทดสอบออฟไลน์","Offline test account","离线测试账号"))
			add_text(content,"LV %d  •  %s"%[game.level,format_playtime(game.total_play_seconds())])
			add_button(content,localized("กลับหน้าล็อบบี้","Return to lobby","返回大厅"),func():
				game.save_playtime()
				game.session_started_msec=-1
				game.started=false
				game.auto=false
				game.stick=Vector2.ZERO
				open_page("Start"))
	add_text(content,localized("บันทึกการตั้งค่าอัตโนมัติ","Settings are saved automatically","自动保存设置"))
	# Keep content scrollable on short screens, including the graphics help text.
	var space := Control.new()
	space.custom_minimum_size.y=180
	content.add_child(space)

func start_editor():
	close_page()
	_reset_touches()
	game.auto=false
	editor_snapshot.clear()
	for key in editable_hud:
		var c: Control=editable_hud[key]
		editor_snapshot[key]=[c.position,c.scale,c.modulate.a]
	editor_panel=PanelContainer.new()
	editor_panel.position=Vector2(390,130)
	editor_panel.size=Vector2(500,280)
	editor_panel.z_index=20
	root.add_child(editor_panel)
	var col := VBoxContainer.new()
	editor_panel.add_child(col)
	editor_title=Label.new()
	editor_title.text=localized("แตะปุ่มเพื่อเลือก แล้วลากเพื่อย้าย","Tap a HUD element, then drag","点击界面元素并拖动")
	col.add_child(editor_title)
	var picker := OptionButton.new()
	var keys := editable_hud.keys()
	for key in keys: picker.add_item(key)
	picker.select(keys.find("◉"))
	picker.item_selected.connect(func(i):select_editor_item(editable_hud[keys[i]]))
	col.add_child(picker)
	add_text(col,localized("ขนาด","Size","大小"))
	editor_size=HSlider.new()
	editor_size.min_value=0.4
	editor_size.max_value=1.8
	editor_size.step=0.05
	editor_size.custom_minimum_size.y=36
	col.add_child(editor_size)
	editor_size.value_changed.connect(func(v):
		if is_instance_valid(editor_selected) and not editor_refresh:
			editor_selected.scale=Vector2.ONE*v
			clamp_editor_control(editor_selected))
	add_text(col,localized("ความโปร่งใส","Opacity","透明度"))
	editor_alpha=HSlider.new()
	editor_alpha.min_value=0.2
	editor_alpha.max_value=1
	editor_alpha.step=0.05
	editor_alpha.custom_minimum_size.y=36
	col.add_child(editor_alpha)
	editor_alpha.value_changed.connect(func(v):
		if is_instance_valid(editor_selected) and not editor_refresh: editor_selected.modulate.a=v)
	var row := HBoxContainer.new()
	col.add_child(row)
	add_button(row,localized("คืนค่าปุ่ม","Reset item","重置元素"),func():
		for key in editable_hud:
			if editable_hud[key]==editor_selected: restore_editor_item(key,hud_defaults[key]))
	add_button(row,localized("คืนค่าทั้งหมด","Reset all","全部重置"),func():
		for key in editable_hud: restore_editor_item(key,hud_defaults[key]))
	var actions := HBoxContainer.new()
	col.add_child(actions)
	add_button(actions,localized("ยกเลิก","Cancel","取消"),func():finish_editor(false))
	add_button(actions,localized("บันทึก","Save","保存"),func():finish_editor(true))
	select_editor_item(joystick)

func select_editor_item(c: Control):
	editor_selected=c
	editor_refresh=true
	for key in editable_hud:
		if editable_hud[key]==c: editor_title.text=key
	editor_size.value=c.scale.x
	editor_alpha.value=c.modulate.a
	editor_refresh=false

func clamp_editor_control(c: Control):
	c.position=c.position.clamp(Vector2.ZERO,(Vector2(1280,720)-c.size*c.scale).max(Vector2.ZERO))

func restore_editor_item(key: String, data: Array):
	var c: Control=editable_hud[key]
	c.position=data[0]
	c.scale=data[1]
	c.modulate.a=data[2]
	if c==editor_selected: select_editor_item(c)

func finish_editor(commit: bool):
	for key in editable_hud:
		var c: Control=editable_hud[key]
		if commit:
			config.set_value("position",key,c.position)
			config.set_value("scale",key,c.scale)
			config.set_value("opacity",key,c.modulate.a)
		else: restore_editor_item(key,editor_snapshot[key])
	if commit: config.save("user://zmb.cfg")
	editor_panel.queue_free()
	editor_panel=null
	editor_selected=null
	editor_finger=-1
	open_page("Settings")

func editor_input(event: InputEvent) -> bool:
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		return editor_finger!=-1 or not editor_panel.get_global_rect().has_point(event.position)
	var pos := Vector2.ZERO
	var finger := -2
	var pressed := false
	var release := false
	var drag := false
	if event is InputEventScreenTouch:
		pos=event.position
		finger=event.index
		pressed=event.pressed
		release=not event.pressed
	elif event is InputEventScreenDrag:
		pos=event.position
		finger=event.index
		drag=true
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		pos=event.position
		pressed=event.pressed
		release=not event.pressed
	elif event is InputEventMouseMotion:
		pos=event.position
		drag=true
	else: return true
	if release and editor_finger==finger:
		editor_finger=-1
		return true
	if drag and editor_finger==finger and is_instance_valid(editor_selected):
		editor_selected.position=pos-editor_offset
		clamp_editor_control(editor_selected)
		return true
	if editor_panel.get_global_rect().has_point(pos): return false
	if pressed:
		var items := editable_hud.values()
		items.reverse()
		for c in items:
			if c.get_global_rect().has_point(pos):
				select_editor_item(c)
				editor_finger=finger
				editor_offset=pos-c.position
				break
	return true

func enter_named_character(chosen_name: String, is_male: bool):
	var cleaned:=chosen_name.strip_edges()
	if not cleaned.is_empty(): game.character_name=cleaned.left(20)
	config.set_value("character","name",game.character_name)
	config.save("user://zmb.cfg")
	game.begin(is_male)
	game.load_profile("user://zmb_character_"+game.character_name.sha256_text()+".cfg")
	close_page()

func open_page(page:String):
	if page=="GM" and not game.gm_allowed(): return
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
	if page in ["Settings","News","Ranking","Shop","Quest","Social","Trade","Market","Map","GM"]:
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
			tab.set_meta("inventory_tab",key)
			if key==page:
				var selected := StyleBoxFlat.new()
				selected.bg_color=Color("75232c")
				selected.border_color=Color("ca5962")
				selected.set_border_width_all(1)
				selected.set_corner_radius_all(8)
				for state in ["normal","hover","pressed","focus"]:
					tab.add_theme_stylebox_override(state,selected)
				tab.add_theme_color_override("font_color",Color.WHITE)
				tab.add_theme_color_override("font_hover_color",Color.WHITE)
				tab.add_theme_color_override("font_pressed_color",Color.WHITE)
	language_menu(header,page)
	if page not in ["Start","Revive"]:
		close_button=add_button(header,"×",close_page)
		close_button.custom_minimum_size=Vector2(44,44)
	if page in INVENTORY_PAGES:
		body.add_child(HSeparator.new())
	if page=="Settings":
		build_settings(body)
		return
	var scroll := ScrollContainer.new()
	modal_scroll=scroll
	scroll.scroll_deadzone=12
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	match page:
		"GM": GM_PAGE.build(self,content)
		"Start":
			add_text(content,"ZMB • SPIRIT PLAGUE\nAncient China | Offline prototype\nSelect a character to enter the village.")
			add_text(content,localized("ชื่อตัวละคร (ไทย / English / 中文)","Character name (ไทย / English / 中文)","角色名称 (ไทย / English / 中文)"))
			var name_input:=LineEdit.new()
			name_input.text=game.character_name
			name_input.max_length=20
			name_input.custom_minimum_size.y=42
			name_input.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
			content.add_child(name_input)
			start_button=add_button(content,"Male warrior",func():enter_named_character(name_input.text,true))
			add_button(content,"Female warrior",func():enter_named_character(name_input.text,false))
		"Bag","Storage","Character","Skills":
			build_inventory_page(content,page)
		"Revive":
			add_text(content,"You fell to the spirit plague.")
			add_button(content,"Revive",func():game.revive(); close_page())
		"Trade": ONLINE_PAGES.trade(self,content)
		"Shop": preload("res://service_pages.gd").new().shop(self,content)
		"Market": ONLINE_PAGES.market(self,content)
		"Quest": QUEST_PAGE.build(self,content)
		"Social": ONLINE_PAGES.social(self,content)
		"Ranking": preload("res://service_pages.gd").new().ranking(self,content)
		"News": preload("res://service_pages.gd").new().news(self,content)
		"Map": ONLINE_PAGES.world_map(self,content)
