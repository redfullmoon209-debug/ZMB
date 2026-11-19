extends SceneTree

func _initialize(): call_deferred("run")

func touch(index: int, pos: Vector2, pressed: bool):
	var event := InputEventScreenTouch.new()
	event.index=index
	event.position=pos
	event.pressed=pressed
	root.push_input(event,true)

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.critical_chance=0.0
	world.ui.close_page()
	var arm: Node3D=world.player_visual.get_node("SwordArm")
	var buttons: Dictionary={}
	for b in world.ui.buttons: buttons[b.get_meta("hud_key")]=b
	var joy: Vector2=world.ui.joystick.get_global_rect().get_center()+Vector2(0,-45)
	var enemy: Node3D=world.enemies[0]
	var old_hp: float=enemy.get_meta("hp")
	touch(0,joy,true)
	touch(1,buttons["ATTACK"].get_global_rect().get_center(),true)
	touch(1,buttons["ATTACK"].get_global_rect().get_center(),false)
	assert(world.attack_pose_count==1 and world.stick.y< -0.5)
	assert(enemy.get_meta("hp")==old_hp)
	touch(0,joy,false)
	await create_timer(0.16).timeout
	assert(arm.rotation.length()>0.2)
	await create_timer(0.35).timeout
	assert(arm.rotation.length()<0.01)
	world.player.position=Vector3(0,0,-18)
	enemy.position=Vector3(0,0,-20)
	enemy.set_meta("hp",1000.0)
	world.target=enemy
	for skill in range(4):
		world.cooldown=0
		old_hp=enemy.get_meta("hp")
		var old_mp: float=world.mp
		var count: int=world.attack_pose_count
		var key: String="ATTACK" if skill==0 else "SKILL %d"%skill
		var pos: Vector2=buttons[key].get_global_rect().get_center()
		touch(1,pos,true)
		touch(1,pos,false)
		assert(world.attack_pose_count==count+1)
		assert(enemy.get_meta("hp")==old_hp-world.gm_attack_power-skill*7)
		assert(world.mp==old_mp-skill*5)
		assert(world.cooldown>0)
		await create_timer(0.12).timeout
		assert(arm.rotation.length()>0.1)
	print("PASS: all four touch combat buttons animate and deal damage; town preview and simultaneous joystick protected")
	world.critical_chance=1.0
	world.cooldown=0
	old_hp=enemy.get_meta("hp")
	world.attack(0)
	assert(enemy.get_meta("hp")==old_hp-roundi(world.gm_attack_power*1.5))
	var found_crit := false
	var found_normal := false
	for child in world.get_children():
		if child.get_meta("damage_number",false):
			if child.get_meta("critical"):
				found_crit=true
				assert(child.modulate.r>0.9 and child.modulate.g<0.4)
			else:
				found_normal=true
				assert(child.modulate.r==1.0 and child.modulate.g==1.0)
	assert(found_crit and found_normal)
	assert(world.ui.damage_overlays.size()>=2)
	var drop: Node3D=world.box(world.player.position+Vector3(1.2,0.25,0),Vector3.ONE,Color.GOLD,world)
	world.loot.append(drop)
	var coins: int=world.coins
	await physics_frame
	await physics_frame
	assert(world.coins==coins+5 and world.loot.is_empty())
	await create_timer(1.0).timeout
	assert(world.ui.damage_overlays.is_empty())
	for child in world.get_children(): assert(not child.get_meta("damage_number",false))
	print("PASS: critical and normal damage colors, float cleanup, automatic contact pickup")
	quit()
