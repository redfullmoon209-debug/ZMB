extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	assert(world.in_safe_zone())
	for enemy in world.enemies:
		assert(not world.is_safe_position(enemy.position,0.6))
		assert(not world.is_safe_position(enemy.get_meta("home"),0.6))
	var enemy: Node3D = world.enemies[0]
	world.player.position = Vector3(0,0,-12.5)
	enemy.position = Vector3(0,0,-13.8)
	world.target = enemy
	var old_hp: float = enemy.get_meta("hp")
	world.attack(0)
	assert(enemy.get_meta("hp") == old_hp)
	world.auto = true
	world.hp = 50
	world.mp = 50
	for i in range(30): await physics_frame
	assert(world.in_safe_zone() and not world.auto and world.target == null)
	assert(world.hp > 50 and world.mp > 50)
	assert(not world.is_safe_position(enemy.position,0.6))
	world.player.position = Vector3(0,0,-16)
	assert(not world.in_safe_zone())
	enemy.position=Vector3(0,0,-17.8)
	enemy.set_meta("hp",15.0)
	world.target=enemy
	world.attack(0)
	assert(world.xp==25)
	world.collect()
	assert(world.items.size()==1 and world.coins==5)
	world.revive()
	assert(world.in_safe_zone() and world.hp==100 and world.mp==100)
	print("PASS: town protected, Auto Hunt stays inside, outside combat and loot work, revive returns to town")
	quit()
