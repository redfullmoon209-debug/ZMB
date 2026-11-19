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
	assert(is_equal_approx(mini_rect.size.x,mini_rect.size.y))
	var camera_zoom: float=world.zoom
	var original_map_zoom: float=hud.minimap.map_zoom
	for b in hud.buttons:
		if b.text=="+": b.pressed.emit()
	assert(hud.minimap.map_zoom>original_map_zoom and world.zoom==camera_zoom)
	for b in hud.buttons:
		if b.text=="−": b.pressed.emit()
	assert(hud.minimap.map_zoom==original_map_zoom)
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
	for category in range(4):
		hud.quest_tab=category
		hud.open_page("Quest")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	hud.quest_tab=0
	hud.open_page("Quest")
	await process_frame
	assert(hud.quest_claim_button.disabled)
	assert(not world.claim_quest("main"))
	world.monsters_defeated=30
	hud.update_quest_ui()
	assert(not hud.quest_claim_button.disabled)
	hud.quest_claim_button.pressed.emit()
	await process_frame
	assert(world.coins==115 and world.is_quest_claimed("main") and hud.quest_tab==3)
	assert(not world.claim_quest("main"))
	print("PASS: four quest tabs, progress and one-time rewards")
	for category in range(3):
		hud.social_tab=category
		for sub in range(3):
			hud.social_sub=sub
			hud.open_page("Social")
			await process_frame
			assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	hud.open_page("Trade")
	await process_frame
	var trade_grids: Array=hud.panel.find_children("*","GridContainer",true,false)
	assert(trade_grids.size()==3)
	assert(trade_grids[0].get_child_count()==48 and trade_grids[1].get_child_count()==30 and trade_grids[2].get_child_count()==30)
	trade_grids[0].get_child(0).pressed.emit()
	assert(hud.trade_selected.size()==1 and world.items.size()==1)
	for category in range(4):
		hud.market_tab=category
		hud.open_page("Market")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	hud.market_tab=1
	hud.market_selected=0
	hud.open_page("Market")
	await process_frame
	for node in hud.panel.find_children("*","Button",true,false):
		if node.text==hud.localized("ยืนยันลงขาย (ทดสอบ)","Confirm listing (demo)","确认挂单（测试）"):
			node.pressed.emit()
			break
	assert(world.items.is_empty() and hud.market_listings.size()==1)
	await process_frame
	for node in hud.panel.find_children("*","Button",true,false):
		if node.text==hud.localized("ยกเลิก","Cancel","取消"):
			node.pressed.emit()
			break
	assert(world.items.size()==1 and hud.market_listings.is_empty() and hud.market_history.size()==1)
	hud.warp_selected=1
	hud.open_page("Map")
	await process_frame
	for node in hud.panel.find_children("*","Button",true,false):
		if node.text==hud.localized("ยืนยันวาร์ป","Confirm warp","确认传送"):
			node.pressed.emit()
			break
	assert(world.player.position.distance_to(Vector3(0,0,-11))<0.1)
	print("PASS: social tabs, trade slots, market escrow/cancel and safe-zone warp")
	assert(world.gm_allowed() and is_instance_valid(hud.gm_button))
	hud.gm_button.pressed.emit()
	await process_frame
	assert(hud.selected_page=="GM")
	assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	var old_gold: int=world.coins
	assert(world.gm_execute("gold",100) and world.coins==old_gold+100)
	assert(world.gm_execute("gold",-100) and world.coins==old_gold)
	assert(world.gm_execute("item",1,"Spirit shard"))
	assert(world.gm_execute("item",-1,"Spirit shard"))
	assert(world.gm_execute("move_speed",2) and world.gm_move_multiplier==2)
	assert(world.gm_execute("move_speed",1))
	assert(world.gm_execute("invincible",1) and world.gm_invincible)
	assert(world.gm_execute("invincible",0))
	assert(world.gm_execute("invisible",1) and not world.player_visual.visible)
	assert(world.gm_execute("invisible",0))
	world.gm_target=world.enemies[0]
	var monster: Node3D=world.gm_target
	assert(world.gm_execute("kill") and not world.enemies.has(monster))
	assert(world.gm_execute("revive") and world.enemies.has(monster))
	world.gm_target=null
	assert(world.gm_execute("kill") and world.hp==0)
	assert(world.gm_execute("revive") and world.hp==100)
	var count: int=world.enemies.size()
	assert(world.gm_execute("spawn",2) and world.enemies.size()==count+1)
	assert(world.gm_execute("event",1) and world.gm_event_active)
	assert(world.gm_execute("announce",0,"Test GM") and world.gm_announcement=="Test GM")
	hud.gm_tab=1
	for category in range(6):
		hud.gm_server_tab=category
		hud.open_page("GM")
		await process_frame
		assert(hud.panel.get_rect().end.x<=1280 and hud.panel.get_rect().end.y<=720)
	ProjectSettings.set_setting("zmb/offline_gm_test",false)
	assert(not world.gm_allowed() and not world.gm_execute("gold",9999))
	hud.close_page()
	hud.open_page("GM")
	await process_frame
	assert(hud.selected_page=="" and not hud.gm_button.visible)
	ProjectSettings.set_setting("zmb/offline_gm_test",true)
	print("PASS: separate GM icon, local commands, monster kill/revive and release gate")
	print("PASS: news, ranking, 50-slot shops and local gold purchase")
	print("PASS: seven categories, camera setting, HUD drag and cancel")
	print("PASS: all ten right-to-left menu icons visible, selecting a category and dragging long menus works")
	quit()
