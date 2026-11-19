extends CanvasLayer
var game: Node3D
var root: Control
var stats: Label
var target_label: Label
var panel: PanelContainer
var body: VBoxContainer
var chat: LineEdit
var joystick: Button
var lang := 1
var selected_page := ""
var buttons: Array[Button] = []
var touch_actions: Dictionary = {}
var captured_touches: Dictionary = {}
var joystick_finger := -1
var web_bridge_ready := false
var web_diagnostics := false
var diagnostic_timer := 0.0
var browser_window: JavaScriptObject
var web_drag_positions: Dictionary = {}
var start_button: Button
var config := ConfigFile.new()
var names := {"Bag":["กระเป๋า","Bag","背包"],"Storage":["คลัง","Storage","仓库"],"Character":["ตัวละคร","Character","角色"],"Skills":["สกิล","Skills","技能"],"Market":["ตลาดโลก","Market","市场"],"Shop":["ร้านค้า","Shop","商店"],"Quest":["เควส","Quest","任务"],"Social":["สังคม","Social","社交"],"Ranking":["อันดับ","Ranking","排行"],"News":["ประกาศ","News","公告"],"Settings":["ตั้งค่า","Settings","设置"],"Trade":["แลกเปลี่ยน","Trade","交易"],"Map":["แผนที่","Map","地图"]}

func trn(s: String) -> String:
	return names[s][lang] if names.has(s) else s

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
	root.theme=theme
	stats=label("",Vector2(22,18),Vector2(320,100))
	target_label=label("",Vector2(460,18),Vector2(360,70))
	target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
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
	make_button("AUTO",Vector2(880,550),Vector2(90,55),func():game.auto=not game.auto)
	make_button("MONSTER",Vector2(1000,250),Vector2(125,55),func():game.choose_target())
	make_button("PLAYER",Vector2(1135,250),Vector2(120,55),func(): target_label.text="No online players (demo)")
	make_button("HP",Vector2(480,565),Vector2(80,55),func():game.hp=minf(100,game.hp+35))
	make_button("MP",Vector2(570,565),Vector2(80,55),func():game.mp=minf(100,game.mp+35))
	make_button("+ ZOOM",Vector2(880,20),Vector2(100,48),func():game.zoom=maxf(4,game.zoom-1))
	make_button("- ZOOM",Vector2(985,20),Vector2(100,48),func():game.zoom=minf(16,game.zoom+1))
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
		_install_web_touch()

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
	if joystick_finger >= 0 or (_web_capture_active() and e.device == InputEvent.DEVICE_ID_EMULATION):
		return
	if e is InputEventMouseButton:
		game.stick=Vector2.ZERO if not e.pressed else ((e.position-joystick.size/2)/70.0).limit_length()
	elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		game.stick=((e.position-joystick.size/2)/70.0).limit_length()

func _set_touch_stick(pos: Vector2):
	var rect := joystick.get_global_rect()
	game.stick = ((pos - rect.get_center()) / maxf(1.0, minf(rect.size.x, rect.size.y) * 0.46)).limit_length()

func _install_web_touch():
	# Queue native events without taking over the canvas or calling into WASM
	# from inside a DOM callback. Godot drains the queue on its own frame.
	browser_window = JavaScriptBridge.get_interface("window")
	var installed = JavaScriptBridge.eval("""
	(() => {
	  const canvas = document.querySelector('canvas');
	  if (!canvas) return false;
	  if (window.zmbTouchDrain) return true;
	  canvas.style.touchAction = 'none';
	  const active = new Set();
	  const queue = [];
	  window.zmbTouchActive = false;
	  window.zmbTouchDrain = () => JSON.stringify(queue.splice(0));
	  const route = (event) => {
	    const phase = event.type.slice(5);
	    const rect = canvas.getBoundingClientRect();
	    let handled = false;
	    for (const touch of Array.from(event.changedTouches)) {
	      const id = touch.identifier;
	      const x = (touch.clientX - rect.left) / rect.width;
	      const y = (touch.clientY - rect.top) / rect.height;
	      if (phase === 'start') {
	        if (!window.zmbGameplay || !window.zmbTouchReady || touch.target !== canvas) continue;
	        const c = window.zmbChatRect;
	        if (c && x >= c[0] && x <= c[2] && y >= c[1] && y <= c[3]) continue;
	        active.add(id);
	      } else if (!active.has(id)) continue;
	      queue.push([phase, id, x, y]);
	      handled = true;
	      if (phase === 'end' || phase === 'cancel') active.delete(id);
	    }
	    if (handled && event.cancelable) event.preventDefault();
	    window.zmbTouchActive = active.size > 0;
	    // Never stop propagation: the native Godot input path remains available
	    // if the browser integration has to fall back.
	  };
	  for (const type of ['touchstart','touchmove','touchend','touchcancel']) {
	    window.addEventListener(type, route, {capture:true, passive:false});
	  }
	  const reset = () => {
	    active.clear();
	    window.zmbTouchActive = false;
	    queue.push(['reset', -1, 0, 0]);
	  };
	  window.addEventListener('blur', reset);
	  document.addEventListener('visibilitychange', () => { if(document.hidden) reset(); });
	  return true;
	})();
	""", true)
	web_bridge_ready = installed == true and JavaScriptBridge.eval("typeof window.zmbTouchDrain === 'function'", true) == true
	web_diagnostics = OS.has_feature("web")
	print("ZMB touch bridge ready: ",web_bridge_ready)
	if not web_bridge_ready:
		return
	JavaScriptBridge.eval("window.zmbTouchReady = true", true)
	_sync_web_touch()
	get_viewport().size_changed.connect(_sync_web_touch)

func _sync_web_touch():
	if not web_bridge_ready:
		return
	var active: bool = game.started and not is_instance_valid(panel)
	var rect := _web_rect(chat)
	JavaScriptBridge.eval("window.zmbGameplay = %s; window.zmbChatRect = %s" % ["true" if active else "false", JSON.stringify(rect)], true)

func _web_rect(control: Control) -> Array:
	# Canvas stretch includes letterbox offsets on wide phones. Convert both
	# corners to actual window pixels before normalizing to DOM coordinates.
	var transform := get_viewport().get_final_transform()
	var window_size := Vector2(get_window().size)
	var rect := control.get_global_rect()
	var first := (transform * rect.position) / window_size
	var last := (transform * rect.end) / window_size
	return [first.x, first.y, last.x, last.y]

func _poll_web_touch():
	if not web_bridge_ready:
		return
	var data = JavaScriptBridge.eval("window.zmbTouchDrain()", true)
	if not data is String:
		web_bridge_ready = false
		JavaScriptBridge.eval("window.zmbTouchReady = false", true)
		_reset_touches()
		return
	var entries = JSON.parse_string(data)
	if entries is Array:
		for entry in entries:
			if entry is Array: _web_touch(entry)

func _web_capture_active() -> bool:
	return web_bridge_ready and JavaScriptBridge.eval("window.zmbTouchActive === true", true) == true

func _web_touch(args: Array):
	if args.size() < 4:
		return
	var phase := str(args[0])
	var index := int(args[1])
	var window_pos := Vector2(float(args[2]), float(args[3])) * Vector2(get_window().size)
	var pos := get_viewport().get_final_transform().affine_inverse() * window_pos
	match phase:
		"start":
			if not _touch_start(index, pos):
				web_drag_positions[index] = pos
		"move":
			if not _touch_move(index, pos) and web_drag_positions.has(index):
				var previous: Vector2 = web_drag_positions[index]
				if pos.x > get_viewport().get_visible_rect().size.x * 0.35:
					game.yaw -= (pos.x - previous.x) * 0.007
				web_drag_positions[index] = pos
		"end", "cancel":
			_touch_end(index)
			web_drag_positions.erase(index)
		"reset":
			_reset_touches()

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
	if not chat.get_global_rect().has_point(pos):
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
	web_drag_positions.clear()
	joystick_finger = -1
	game.stick = Vector2.ZERO

func _input(event: InputEvent):
	if not is_instance_valid(joystick):
		return
	# Godot's mouse emulation represents only one finger. HUD controls use
	# actual touch indices instead, while popup menus still use mouse emulation.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if not captured_touches.is_empty() or (_web_capture_active() and not is_instance_valid(panel) and not chat.get_global_rect().has_point(event.position)):
			get_viewport().set_input_as_handled()
		return
	if _web_capture_active() and not is_instance_valid(panel) and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		if not chat.get_global_rect().has_point(event.position): get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if not event.pressed or event.canceled:
			if _touch_end(event.index):
				get_viewport().set_input_as_handled()
			return
		if _touch_start(event.index, event.position):
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _touch_move(event.index, event.position): get_viewport().set_input_as_handled()

func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(game):
		_reset_touches()

func _process(delta):
	if not is_instance_valid(stats): return
	_poll_web_touch()
	stats.text="ZMB v0.1.3  |  LV %d  |  Touch %d\nHP %d / 100    MP %d / 100\nEXP %d / 100   Gold %d"%[game.level,captured_touches.size(),game.hp,game.mp,game.xp,game.coins]
	if is_instance_valid(game.target): target_label.text="%s • HP %d"%[["Normal","Elite","Boss"][game.target.get_meta("tier")],game.target.get_meta("hp")]
	elif game.auto: target_label.text="AUTO HUNT"
	else: target_label.text="ZMB  •  OFFLINE DEMO"
	if game.hp<=0 and game.started and not is_instance_valid(panel): open_page("Revive")
	# Read-only local gameplay diagnostics used by the exported-Web smoke test.
	diagnostic_timer -= delta
	if web_diagnostics and diagnostic_timer <= 0:
		diagnostic_timer = 0.10
		var controls := {}
		for b in buttons: controls[b.text] = _web_rect(b)
		if is_instance_valid(start_button): controls["START"] = _web_rect(start_button)
		var d := {"version":"0.1.3","ready":web_bridge_ready,"started":game.started,"controls":controls,"stick":[game.stick.x,game.stick.y],"touches":captured_touches.size(),"position":[game.player.position.x,game.player.position.y,game.player.position.z],"velocity":[game.player.velocity.x,game.player.velocity.y,game.player.velocity.z]}
		var payload := JSON.stringify(d)
		if browser_window != null:
			browser_window.zmbDiagnosticsJSON = payload

func close_page():
	if is_instance_valid(panel): panel.queue_free()
	panel=null
	selected_page=""
	_sync_web_touch()

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

func grid(parent:Node,count:int,columns:int,contents:Array=[]):
	var g := GridContainer.new()
	g.columns=columns
	parent.add_child(g)
	for i in range(count):
		var b := Button.new()
		b.text="◆" if i<contents.size() else "·"
		b.tooltip_text=str(contents[i]) if i<contents.size() else "Empty"
		b.custom_minimum_size=Vector2(48,42)
		g.add_child(b)
	return g

func open_page(page:String):
	joystick_finger = -1
	game.stick = Vector2.ZERO
	close_page()
	selected_page=page
	panel=PanelContainer.new()
	root.add_child(panel)
	_sync_web_touch()
	panel.position=Vector2(175,100)
	panel.size=Vector2(930,520)
	panel.z_index=10
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	panel.add_child(margin)
	body=VBoxContainer.new()
	margin.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	var title := Label.new()
	title.text="ZMB  /  "+trn(page)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(title)
	for i in range(3):
		add_button(header,["ไทย","EN","中文"][i],func(): lang=i; config.set_value("ui","lang",lang); config.save("user://zmb.cfg"); open_page(page))
	if page not in ["Start","Revive"]: add_button(header,"✕",close_page)
	var scroll := ScrollContainer.new()
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
		"Menu":
			for k in names.keys(): add_button(content,trn(k),func():open_page(k))
		"Bag","Storage","Character","Skills":
			var tabs := HBoxContainer.new()
			content.add_child(tabs)
			for k in ["Bag","Storage","Character","Skills"]: add_button(tabs,trn(k),func():open_page(k))
			var row := HBoxContainer.new()
			content.add_child(row)
			var left := VBoxContainer.new()
			row.add_child(left)
			left.custom_minimum_size.x=390
			var right := VBoxContainer.new()
			row.add_child(right)
			match page:
				"Bag":
					add_text(left,"Equipment • 13 slots")
					grid(left,13,4)
					grid(right,48,8,game.items)
				"Storage":
					add_text(left,"Storage preview")
					grid(left,48,8)
					grid(right,48,8,game.items)
				"Character":
					add_text(left,"Warrior • model placeholder")
					add_text(right,"Level %d\nHP %d / MP %d\nGold %d"%[game.level,game.hp,game.mp,game.coins])
				"Skills":
					add_text(left,"Weapon selection • local combat")
					for i in range(3): add_button(left,["Sword / melee","Spear / mid","Gun / ranged"][i],func(): game.weapon=i)
					grid(right,15,5,["Strike","Spirit thrust","Sweep"])
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
						config.set_value("position",b.text,b.position)
						config.set_value("opacity",b.text,b.modulate.a)
						config.set_value("scale",b.text,b.scale)
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
		"Map": add_text(content,"Village of the Spirit Plague\nPosition: %s"%str(game.player.position))
