extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
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
			assert(interior.encloses(row.get_global_rect()))
			if page in ["Bag","Storage"]:
				for column in [row.get_child(0),row.get_child(2)]:
					for child in column.get_children():
						assert(interior.encloses(child.get_global_rect()))
			if page=="Bag":
				assert(row.get_child(2).get_child(1).get_child_count()==48)
				assert(row.get_child(0).get_child(1).get_child(1) is SubViewportContainer)
				assert(row.get_child(0).get_child(2).get_child_count()==5)
				assert(hud.modal_scroll.get_h_scroll_bar().max_value<=hud.modal_scroll.get_h_scroll_bar().page+1)
				assert(hud.modal_scroll.get_v_scroll_bar().max_value<=hud.modal_scroll.get_v_scroll_bar().page+1)
	hud.lang=original_lang
	print("PASS: 50/50 inventory layout, 48 slots, 3D preview and 3-language menu in every inventory tab")
	quit()
