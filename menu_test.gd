extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	var hud = world.ui
	var mini_rect: Rect2=hud.minimap.get_global_rect()
	assert(mini_rect.end.x<=1280 and mini_rect.position.y>=0)
	assert(hud.camera_mode_button.get_global_rect().position.y>mini_rect.end.y)
	for b in hud.buttons:
		assert(not mini_rect.intersects(b.get_global_rect()))
		if b.get_meta("hud_key")=="MENU":
			assert(b.get_global_rect().end.x<mini_rect.position.x)
	assert(hud.minimap.map_point(Vector3(10,0,0)).x>hud.minimap.map_point(Vector3.ZERO).x)
	hud.open_page("Menu")
	await process_frame
	await process_frame
	assert(hud.menu_items.size()==10)
	var last_x := 1300.0
	for key in hud.MENU_PAGES:
		var b: Button=hud.menu_items[key]
		var rect := b.get_global_rect()
		assert(b.icon!=null and rect.position.x<last_x and rect.position.x>=0 and rect.end.x<=1280)
		last_x=rect.position.x
	hud.menu_items["Settings"].pressed.emit()
	await process_frame
	await process_frame
	assert(hud.selected_page=="Settings" and hud.modal_scroll!=null)
	var scroll: ScrollContainer=hud.modal_scroll
	var pos := scroll.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.index=2
	touch.position=pos
	touch.pressed=true
	root.push_input(touch,true)
	var drag := InputEventScreenDrag.new()
	drag.index=2
	drag.position=pos-Vector2(0,160)
	drag.relative=Vector2(0,-160)
	root.push_input(drag,true)
	assert(scroll.scroll_vertical>0 and hud.selected_page=="Settings")
	touch.position=drag.position
	touch.pressed=false
	root.push_input(touch,true)
	for category in range(7):
		hud.settings_category=category
		hud.open_page("Settings")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	hud.save_setting("camera_sensitivity",150)
	assert(is_equal_approx(world.camera_sensitivity,1.5))
	hud.save_setting("camera_sensitivity",100)
	hud.start_editor()
	await process_frame
	var original: Vector2=hud.joystick.position
	var p: Vector2=hud.joystick.get_global_rect().get_center()
	touch.index=4
	touch.pressed=true
	touch.position=p
	root.push_input(touch,true)
	drag.index=4
	drag.position=p+Vector2(20,-20)
	root.push_input(drag,true)
	assert(hud.joystick.position.distance_to(original+Vector2(20,-20))<1)
	assert(world.stick==Vector2.ZERO)
	touch.pressed=false
	root.push_input(touch,true)
	hud.finish_editor(false)
	assert(hud.joystick.position==original)
	for category in range(3):
		hud.news_tab=category
		hud.open_page("News")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	for category in range(6):
		hud.ranking_tab=category
		hud.open_page("Ranking")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	for category in range(3):
		hud.shop_tab=category
		hud.open_page("Shop")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
		if category<2:
			var grids: Array=hud.panel.find_children("*","GridContainer",true,false)
			assert(grids.size()==1 and grids[0].columns==10 and grids[0].get_child_count()==50)
	hud.shop_tab=0
	hud.shop_selected=0
	world.coins=20
	hud.open_page("Shop")
	await process_frame
	for node in hud.panel.find_children("*","Button",true,false):
		if node.text==hud.localized("ซื้อ (ทดสอบ)","Buy (demo)","购买（测试）"):
			node.pressed.emit()
			break
	assert(world.coins==15 and hud.shop_history.size()==1 and world.items.size()==1)
	print("PASS: news, ranking, 50-slot shops and local gold purchase")
	print("PASS: seven categories, camera setting, HUD drag and cancel")
	print("PASS: all ten right-to-left menu icons visible, selecting a category and dragging long menus works")
	quit()
