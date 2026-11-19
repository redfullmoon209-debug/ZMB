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
	print("PASS: all ten right-to-left menu icons visible, selecting a category and dragging long menus works")
	quit()
