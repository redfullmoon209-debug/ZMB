extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	world.set_camera_follow(false)
	var initial_pitch: float=world.pitch
	var initial_yaw: float=world.yaw
	world.rotate_camera(Vector2(40,-60))
	assert(world.pitch > initial_pitch and not is_equal_approx(world.yaw,initial_yaw))
	world.rotate_camera(Vector2(0,2000))
	assert(is_equal_approx(world.pitch,deg_to_rad(-8.0)))
	world.rotate_camera(Vector2(0,-2000))
	assert(is_equal_approx(world.pitch,deg_to_rad(78.0)))
	world.pitch=deg_to_rad(28.0)
	world.yaw=0.0
	world.set_camera_follow(true)
	world.stick=Vector2(1,0)
	for i in range(45): await physics_frame
	assert(world.player.velocity.x>1 and absf(world.player.velocity.z)<0.05)
	assert(absf(wrapf(world.yaw-world.player_visual.rotation.y-PI,-PI,PI))<0.15)
	assert(world.camera.position.x < world.player.position.x)
	var locked_yaw: float=world.yaw
	var old_pitch: float=world.pitch
	world.rotate_camera(Vector2(100,-20))
	assert(is_equal_approx(world.yaw,locked_yaw) and world.pitch>old_pitch)
	world.set_camera_follow(false)
	world.rotate_camera(Vector2(50,0))
	assert(not is_equal_approx(world.yaw,locked_yaw))
	# Push actual touch events through the HUD input router, including a joystick finger.
	world.zoom=10.0
	var hud=world.ui
	var joy: Vector2=hud.joystick.get_global_rect().get_center()+Vector2(0,-50)
	touch(1,joy,true)
	touch(2,Vector2(470,300),true)
	touch(3,Vector2(670,300),true)
	var before_pitch: float=world.pitch
	drag(3,Vector2(770,300),Vector2(100,0))
	assert(world.zoom<8.0 and world.stick.y<0 and is_equal_approx(world.pitch,before_pitch))
	drag(3,Vector2(570,300),Vector2(-200,0))
	assert(world.zoom>10.0 and world.zoom<=16.0)
	touch(3,Vector2(570,300),false)
	drag(2,Vector2(470,280),Vector2(0,-20))
	assert(world.pitch>before_pitch)
	touch(2,Vector2(470,280),false)
	touch(1,joy,false)
	assert(world.stick==Vector2.ZERO and hud.camera_touches.is_empty())
	assert(not hud.buttons.any(func(b): return "ZOOM" in b.text))
	print("PASS: free camera yaw/pitch, pitch limits, stable movement, behind-player follow mode")
	print("PASS: pinch zoom in/out with independent joystick finger and single-finger resume")
	quit()

func touch(index: int, pos: Vector2, pressed: bool):
	var event := InputEventScreenTouch.new()
	event.index=index
	event.position=pos
	event.pressed=pressed
	root.push_input(event,true)

func drag(index: int, pos: Vector2, relative: Vector2):
	var event := InputEventScreenDrag.new()
	event.index=index
	event.position=pos
	event.relative=relative
	root.push_input(event,true)
