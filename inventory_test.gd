extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	assert(world.session_seconds()==0 and world.session_started_msec<0)
	world.begin(true)
	assert(world.session_started_msec>=0 and world.first_play_unix>0)
	await create_timer(1.2).timeout
	assert(world.session_seconds()>=1 and world.total_play_seconds()>=1)
	var hud = world.ui
	var original_lang: int=hud.lang
	for language in range(3):
		hud.lang=language
		for page in hud.INVENTORY_PAGES:
			hud.open_page(page)
			await process_frame
			await process_frame
			var rect: Rect2=hud.panel.get_global_rect()
			assert(rect.end.x<=1280 and rect.end.y<=720)
			var header: HBoxContainer=hud.body.get_child(0)
			var interior := rect.grow(-39.0)
			assert(header.get_global_rect().position.y>=rect.position.y+68)
			assert(interior.encloses(header.get_global_rect()))
			assert(interior.encloses(hud.modal_scroll.get_global_rect()))
			for control in header.get_children():
				assert(interior.encloses(control.get_global_rect()))
			var lang_button: MenuButton=header.get_child(5)
			assert(lang_button.get_popup().item_count==3)
			var row: HBoxContainer=hud.modal_scroll.get_child(0).get_child(0)
			assert(absf(row.get_child(0).size.x-row.get_child(2).size.x)<2)
			assert(interior.encloses(row.get_global_rect()),str(page," lang=",language," row=",row.get_global_rect()," interior=",interior))
			if page=="Character":
				assert(hud.character_values.size()==19)
				assert(hud.character_values["name"].text==world.character_name)
				assert(hud.character_values["session"].text!="00:00:00")
			if page in ["Bag","Storage"]:
				for column in [row.get_child(0),row.get_child(2)]:
					for child in column.get_children():
						assert(interior.encloses(child.get_global_rect()))
			if page=="Bag":
				assert(row.get_child(2).get_child(1).get_child_count()==50)
				assert(row.get_child(0).get_child(1).get_child(1) is SubViewportContainer)
				assert(row.get_child(0).get_child(2).get_child_count()==5)
				var gear := row.get_child(0).get_child(1)
				var accessories := row.get_child(0).get_child(2)
				for side in [gear.get_child(0),gear.get_child(2),accessories]:
					for slot in side.get_children():
						assert(is_equal_approx(slot.size.x,slot.size.y))
						assert(is_equal_approx(slot.size.x,48.0 if side==accessories else 64.0))
				assert(accessories.get_global_rect().position.y>=gear.get_global_rect().end.y)
				assert(hud.modal_scroll.get_h_scroll_bar().max_value<=hud.modal_scroll.get_h_scroll_bar().page+1)
				assert(hud.modal_scroll.get_v_scroll_bar().max_value<=hud.modal_scroll.get_v_scroll_bar().page+1)
	hud.lang=original_lang
	world.previous_play_seconds=0
	world.session_started_msec=Time.get_ticks_msec()
	world.level=1
	world.bag_unlocked_pages=1
	assert(world.bag_capacity()==50)
	hud.bag_page=1
	hud.open_page("Bag")
	await process_frame
	await process_frame
	var locked_row: HBoxContainer=hud.modal_scroll.get_child(0).get_child(0)
	var locked_grid: GridContainer=locked_row.get_child(2).get_child(1)
	assert(locked_grid.get_child_count()==50 and locked_grid.get_child(0).disabled)
	assert(hud.modal_scroll.get_v_scroll_bar().max_value<=hud.modal_scroll.get_v_scroll_bar().page+1)
	world.level=10
	assert(world.bag_capacity()==100)
	world.previous_play_seconds=3*3600
	assert(world.bag_capacity()==150)
	world.coins=world.BAG_UNLOCK_PRICE
	assert(world.buy_bag_unlock() and world.bag_capacity()==200 and world.coins==0)
	assert(not world.buy_bag_unlock())
	world.items.assign([])
	for i in range(51): world.items.append("HP Potion")
	world.items[50]="Rare Sword"
	hud.bag_page=1
	hud.open_page("Bag")
	await process_frame
	await process_frame
	var unlocked_row: HBoxContainer=hud.modal_scroll.get_child(0).get_child(0)
	var unlocked_grid: GridContainer=unlocked_row.get_child(2).get_child(1)
	assert(unlocked_grid.get_child(0).tooltip_text=="Rare Sword")
	unlocked_grid.get_child(0).pressed.emit()
	assert(world.ui.item_dialog.visible)
	world.ui.item_dialog.custom_action.emit("main")
	assert(world.equipment.get("main")=="Rare Sword")
	var path := "user://bag_test_%d.cfg"%Time.get_ticks_usec()
	world.profile_path=path
	world.save_profile()
	world.bag_unlocked_pages=1
	world.load_profile(path)
	assert(world.bag_capacity()==200)
	world.level=50
	assert(world.bag_capacity()==300)
	assert(not world.buy_bag_unlock())
	world.profile_path=""
	DirAccess.remove_absolute(path)
	print("PASS: 300 slots, locked pages, level/time/demo token expansion, second-page item index and persisted unlocks")
	print("PASS: 50/50 inventory layout, 50 slots per page, 3D preview and 3-language menu in every inventory tab")
	quit()
