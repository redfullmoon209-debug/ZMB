extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	var enemy: Node3D=world.enemies[0]
	for other in world.enemies.duplicate():
		if other!=enemy: world.enemies.erase(other);other.queue_free()
	enemy.position=Vector3(0,0,-25)
	enemy.set_meta("home",enemy.position)
	world.player.position=Vector3(0,0,-20)
	var auto_button: Button=world.ui.editable_hud["AUTO"]
	auto_button.pressed.emit()
	world.ui.update_auto_hunt_indicator(0.25)
	assert(world.auto and world.ui.auto_hunt_art.rotation>0 and auto_button.rotation==0)
	auto_button.pressed.emit()
	world.ui.update_auto_hunt_indicator(0.25)
	assert(not world.auto and world.ui.auto_hunt_art.rotation==0)
	var before: Vector3=enemy.position
	for i in range(30): await physics_frame
	assert(enemy.position.distance_to(world.player.position)<before.distance_to(world.player.position))
	enemy.position=world.player.position+Vector3(0,0,-1.4)
	var hp: float=world.hp
	for i in range(4): await physics_frame
	assert(world.hp<hp)
	var after: float=world.hp
	for i in range(20): await physics_frame
	assert(world.hp==after)
	world.target=enemy
	world.critical_chance=0.0
	world.attack(1)
	assert(world.skill_cooldowns[1]>2.9)
	world.ui.update_combat_cooldowns()
	assert(world.ui.cooldown_labels[1].visible)
	var effect_found := false
	for child in world.get_children():
		if child.get_meta("combat_effect",-1)==1: effect_found=true
	assert(effect_found)
	world.player.position=Vector3.ZERO
	for i in range(180): await physics_frame
	assert(enemy.position.distance_to(enemy.get_meta("home"))<0.2)
	print("PASS: monster chase, timed attack, return home, skill effect and cooldown HUD")
	quit()
