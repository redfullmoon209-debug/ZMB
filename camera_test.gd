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
	print("PASS: free camera yaw/pitch, pitch limits, stable movement, behind-player follow mode")
	quit()
