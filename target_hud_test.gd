extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.critical_chance=0.0
	world.ui.close_page()
	var hud=world.ui
	assert(world.demo_players.size()==2)
	world.choose_player_target()
	assert(world.target==world.demo_players[0])
	world.target=null
	world.select_target_at(world.camera.unproject_position(world.demo_players[0].position+Vector3.UP))
	assert(world.target==world.demo_players[0])
	await physics_frame
	assert(world.target==world.demo_players[0])
	hud.refresh_target_status(true)
	assert(hud.target_bar.visible and hud.target_hp.text=="HP 100 / 100")
	world.attack(0)
	assert(world.target.get_meta("hp")==100)
	world.player.position=Vector3(1.8,0,-16)
	world.choose_player_target()
	assert(world.target==world.demo_players[1])
	world.cooldown=0
	world.attack(0)
	hud.refresh_target_status(false)
	assert(world.target.get_meta("hp")==85)
	assert(hud.target_hp.text=="HP 85 / 100")
	assert(is_equal_approx(hud.target_fill.size.x,246.5))
	assert(world.xp==0 and world.monsters_defeated==0)
	var menu: Button
	for b in hud.buttons:
		if b.text=="MENU": menu=b
	assert(menu.get_global_rect().position.x-hud.gm_button.get_global_rect().end.x>=35)
	print("PASS: demo lock, safe-zone protection, live target HP, no rewards, GM spacing")
	quit()
