extends SceneTree

func _initialize():
	call_deferred("run")

func touch(index: int, pos: Vector2, pressed: bool):
	var event := InputEventScreenTouch.new()
	event.index=index
	event.position=pos
	event.pressed=pressed
	root.push_input(event, true)

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	for i in range(10): await physics_frame
	var hud = world.ui
	var circular: Array[Button]=[]
	for b in hud.buttons:
		if b.get_meta("round",false):
			assert(is_equal_approx(b.size.x,b.size.y),str(b.text,b.size))
			assert(Rect2(Vector2.ZERO,Vector2(1280,720)).encloses(b.get_global_rect()))
			for other in circular:
				assert(not b.get_global_rect().intersects(other.get_global_rect()),"Default buttons overlap")
			circular.append(b)
	assert(circular.size()==14 and is_instance_valid(hud.joystick_knob.texture))
	var jump_button: Button
	var run_button: Button
	var dash_button: Button
	for b in hud.buttons:
		if b.text=="JUMP": jump_button=b
		if b.text=="RUN": run_button=b
		if b.text=="DASH": dash_button=b
	var joy: Vector2=hud.joystick.get_global_rect().get_center()+Vector2(0,-45)
	var jump: Vector2=jump_button.get_global_rect().get_center()
	var run_pos: Vector2=run_button.get_global_rect().get_center()
	var dash: Vector2=dash_button.get_global_rect().get_center()
	touch(0,joy,true)
	assert(world.stick.y < -0.5)
	touch(1,run_pos,true)
	touch(1,run_pos,false)
	assert(world.run_mode and world.stick.y < -0.5)
	touch(2,jump,true)
	assert(world.jump_requested and world.stick.y < -0.5)
	touch(2,jump,false)
	assert(world.stick.y < -0.5)
	for i in range(5): await physics_frame
	assert(world.player.position.y>0.1 and world.player.velocity.z < -1)
	touch(3,dash,true)
	assert(world.dash_time > 0 and world.stick.y < -0.5)
	touch(3,dash,false)
	touch(0,joy,false)
	assert(world.stick==Vector2.ZERO)
	print("PASS: concurrent indexed touch movement, run, jump, and dash")
	quit()
