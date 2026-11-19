extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	var hud=world.ui
	world.hp=50
	world.mp=25
	world.xp=75
	world.level=8
	hud.refresh_player_status()
	assert(hud.status_level.text=="LV 8")
	assert(hud.status_hp.text=="HP  50 / 100")
	assert(hud.status_mp.text=="MP  25 / 100")
	assert(is_equal_approx(hud.status_fill_clips[0].size.x,126.5))
	assert(is_equal_approx(hud.status_fill_clips[1].size.x,63.25))
	assert(hud.status_exp.text=="EXP  75 / 100")
	assert(is_equal_approx(hud.status_fill_clips[2].size.x,189.75))
	assert(is_instance_valid(hud.status_fill_clips[2].get_child(0).texture))
	var original_name: String=world.character_name
	var original_lang: int=hud.lang
	for player_name in ["นักดาบไทย","剑客","NightWalker"]:
		world.character_name=player_name
		for language in range(3):
			hud.lang=language
			hud.refresh_player_status()
			assert(hud.status_name.text==player_name)
	world.character_name=original_name
	hud.lang=original_lang
	world.hp=0
	hud.refresh_player_status()
	assert(hud.status_fill_clips[0].size.x==0)
	assert(hud.editable_hud["STATUS"]==hud.player_status)
	assert(hud.player_status.mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(hud.player_status.get_global_rect()))
	print("PASS: separate HP/MP fills, live labels and editable status group")
	quit()
