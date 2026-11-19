extends Node3D

const HUD = preload("res://hud.gd")
const SAFE_HALF := 13.0
const GATE_HALF := 3.0
const RESPAWN_POINT := Vector3.ZERO
var player: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var enemies: Array[Node3D] = []
var loot: Array[Node3D] = []
var target: Node3D
var hp := 100.0
var mp := 100.0
var xp := 0
var level := 1
var coins := 0
var items: Array[String] = []
var auto := false
var run_mode := false
var weapon := 0
var cooldown := 0.0
var yaw := 0.0
var zoom := 9.0
var stick := Vector2.ZERO
var dash_time := 0.0
var jump_requested := false
var started := false
var male := true
var player_visual: Node3D

func _ready():
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("263c45")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("acb7bb")
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	box(Vector3(0,-0.5,0),Vector3(90,1,90),Color("3c4d3e"),self)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(90,1,90)
	shape.shape = floor_shape
	floor_body.position.y = -0.5
	floor_body.add_child(shape)
	add_child(floor_body)
	build_safe_village()
	for i in range(20):
		var p := Vector3(randf_range(-38,38),0,randf_range(-38,38))
		if is_safe_position(p, 5.0): continue
		box(p+Vector3.UP*1.5,Vector3(0.5,3,0.5),Color("46382a"),self)
		box(p+Vector3.UP*3,Vector3(2.5,2.2,2.5),Color("243f32"),self)
	player = CharacterBody3D.new()
	add_child(player)
	player.position = RESPAWN_POINT
	var c := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	c.shape = capsule
	c.position.y = 0.9
	player.add_child(c)
	player_visual = figure(player,Color("a32f39"))
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	for i in range(12):
		spawn_enemy(i)
	ui = HUD.new()
	ui.game = self
	add_child(ui)

func is_safe_position(p: Vector3, margin: float = 0.0) -> bool:
	return absf(p.x) < SAFE_HALF + margin and absf(p.z) < SAFE_HALF + margin

func in_safe_zone() -> bool:
	return is_instance_valid(player) and is_safe_position(player.position)

func solid_box(p: Vector3, s: Vector3, color: Color):
	var body := StaticBody3D.new()
	add_child(body)
	body.position = p
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = s
	collider.shape = shape
	body.add_child(collider)
	box(Vector3.ZERO, s, color, body)

func sign_at(p: Vector3, words: String, color: Color):
	var sign := Label3D.new()
	sign.text = words
	sign.font_size = 44
	sign.pixel_size = 0.014
	sign.modulate = color
	sign.outline_size = 8
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign)
	sign.position = p

func build_safe_village():
	# Stone courtyard and four guarded exits. Walls are physical, with wide
	# openings aligned to the roads so players choose when to leave town.
	box(Vector3(0,0.015,0),Vector3(26,0.03,26),Color("72736a"),self)
	box(Vector3(0,0.04,0),Vector3(4.5,0.04,38),Color("aca28a"),self)
	box(Vector3(0,0.04,0),Vector3(38,0.04,4.5),Color("aca28a"),self)
	for x in [-8.0,8.0]:
		for z in [-7.0,7.0]: building(Vector3(x,0,z))
	var wall_length := SAFE_HALF-GATE_HALF
	var wall_center := (SAFE_HALF+GATE_HALF)/2.0
	for side in [-1,1]:
		var edge := float(side)*SAFE_HALF
		for wing in [-1,1]:
			var along := float(wing)*wall_center
			solid_box(Vector3(along,1.35,edge),Vector3(wall_length,2.7,0.7),Color("514b42"))
			solid_box(Vector3(edge,1.35,along),Vector3(0.7,2.7,wall_length),Color("514b42"))
			box(Vector3(along,2.83,edge),Vector3(wall_length,0.28,1),Color("282b2c"),self)
			box(Vector3(edge,2.83,along),Vector3(1,0.28,wall_length),Color("282b2c"),self)
			var post := float(wing)*(GATE_HALF+0.45)
			solid_box(Vector3(post,1.8,edge),Vector3(0.65,3.6,0.65),Color("692e2d"))
			solid_box(Vector3(edge,1.8,post),Vector3(0.65,3.6,0.65),Color("692e2d"))
			box(Vector3(post,3.75,edge),Vector3(0.8,0.55,0.8),Color("dfad59"),self)
			box(Vector3(edge,3.75,post),Vector3(0.8,0.55,0.8),Color("dfad59"),self)
		box(Vector3(0,3.9,edge),Vector3(7.8,0.3,1.2),Color("333436"),self)
		box(Vector3(edge,3.9,0),Vector3(1.2,0.3,7.8),Color("333436"),self)
		box(Vector3(0,0.07,edge),Vector3(6,0.08,0.45),Color("65d2a1"),self)
		box(Vector3(edge,0.07,0),Vector3(0.45,0.08,6),Color("65d2a1"),self)
		sign_at(Vector3(0,4.6,edge),"HUNTING GROUNDS • LV 1+",Color("f6c883"))
		sign_at(Vector3(edge,4.6,0),"HUNTING GROUNDS • LV 1+",Color("f6c883"))
	sign_at(Vector3(0,3.3,0),"SPIRIT VILLAGE  /  SAFE ZONE",Color("a7f2bd"))

func box(p: Vector3,s: Vector3,color: Color,parent: Node) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = s
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	parent.add_child(m)
	m.position = p
	return m

func building(p: Vector3):
	var n := Node3D.new()
	add_child(n)
	n.position = p
	box(Vector3(0,1.5,0),Vector3(5,3,4),Color("713c30"),n)
	box(Vector3(0,3.2,0),Vector3(6,0.4,5),Color("20262a"),n)
	for side in [-1,1]:
		var roof := box(Vector3(0,4.0,float(side)*1.25),Vector3(6.2,0.3,3),Color("343d42"),n)
		roof.rotation.x = float(side)*0.48
		box(Vector3(float(side)*2.1,1.4,2.2),Vector3(0.3,2.8,0.3),Color("3d2422"),n)
	box(Vector3(0,1.1,2.02),Vector3(1.2,2.2,0.1),Color("1f2524"),n)

func figure(parent: Node3D,color: Color) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	box(Vector3(0,1.05,0),Vector3(0.65,0.75,0.38),color,n)
	box(Vector3(0,1.67,0),Vector3(0.42,0.42,0.42),Color("c5ad91"),n)
	for side in [-1,1]:
		box(Vector3(float(side)*0.19,0.35,0),Vector3(0.24,0.7,0.26),Color("27292e"),n)
		box(Vector3(float(side)*0.46,1.05,0),Vector3(0.2,0.65,0.24),color,n)
	box(Vector3(0.55,0.85,0.1),Vector3(0.12,0.95,0.12),Color("aebac3"),n)
	return n

func spawn_enemy(i: int):
	var n := Node3D.new()
	add_child(n)
	var tier := 2 if i==11 else (1 if i%4==0 else 0)
	var angle := float(i)*2.39996
	var distance := 24.0 if tier==0 else (32.0 if tier==1 else 39.0)
	n.position = Vector3(sin(angle)*distance,0,cos(angle)*distance)
	# Ring placement can land near a square's corner; force every spawn
	# outside the protected boundary, even after a respawn.
	if is_safe_position(n.position, 2): n.position = n.position.normalized()*28.0
	n.set_meta("home",n.position)
	n.set_meta("spawn_index",i)
	n.set_meta("tier",tier)
	n.set_meta("hp",float(40+80*tier))
	figure(n,[Color("70886b"),Color("b89a51"),Color("7b49a5")][tier])
	n.scale = Vector3.ONE * (1.0+0.35*tier)
	enemies.append(n)

func begin(is_male: bool):
	male = is_male
	player_visual.scale = Vector3.ONE if male else Vector3(0.85,0.94,0.85)
	started = true

func choose_target():
	if in_safe_zone():
		target=null
		return
	var sorted := enemies.filter(func(n): return is_instance_valid(n))
	sorted.sort_custom(func(a,b): return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
	if sorted.is_empty():
		return
	target = sorted[(sorted.find(target)+1)%sorted.size()]

func attack(skill: int):
	if not started or hp<=0 or cooldown>0 or in_safe_zone():
		return
	if not is_instance_valid(target): choose_target()
	if not is_instance_valid(target): return
	var ranges := [2.7,5.5,12.0]
	if player.position.distance_to(target.position)>ranges[weapon]+skill: return
	if mp < skill*5: return
	mp -= skill*5
	cooldown = 0.45+skill*0.2
	var hits := [target]
	if skill==3:
		for n in enemies:
			if n!=target and n.position.distance_to(target.position)<3: hits.append(n)
	for n in hits:
		n.set_meta("hp",float(n.get_meta("hp"))-15-skill*7)
		if n.get_meta("hp")<=0:
			var drop := box(n.position+Vector3.UP*0.25,Vector3(0.5,0.5,0.5),Color("e7c46d"),self)
			loot.append(drop)
			xp += 25
			if xp>=100:
				level+=1
				xp-=100
			enemies.erase(n)
			n.queue_free()
			if n==target: target=null
			var spawn_index: int = n.get_meta("spawn_index")
			get_tree().create_timer(5).timeout.connect(func(): spawn_enemy(spawn_index))

func collect():
	for d in loot.duplicate():
		if player.position.distance_to(d.position)<4 and items.size()<48:
			items.append("Spirit shard")
			coins+=5
			loot.erase(d)
			d.queue_free()

func revive():
	hp=100
	mp=100
	player.position=RESPAWN_POINT
	player.velocity=Vector3.ZERO
	target=null
	auto=false

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): yaw-=event.relative.x*0.007
	if event is InputEventScreenDrag and event.position.x>get_viewport().get_visible_rect().size.x*0.35: yaw-=event.relative.x*0.007
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom=maxf(4,zoom-1)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom=minf(16,zoom+1)
		if event.button_index==MOUSE_BUTTON_LEFT and not in_safe_zone():
			var nearest := 65.0
			for n in enemies:
				if camera.is_position_behind(n.position): continue
				var d := camera.unproject_position(n.position+Vector3.UP).distance_to(event.position)
				if d<nearest:
					nearest=d
					target=n
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: jump_requested=true
			KEY_SHIFT: dash_time=0.18
			KEY_F: attack(0)
			KEY_1: attack(1)
			KEY_2: attack(2)
			KEY_3: attack(3)
			KEY_TAB: choose_target()
			KEY_E: collect()

func _physics_process(delta: float):
	if not is_instance_valid(player): return
	var offset := Vector3(sin(yaw)*zoom,zoom*0.65,cos(yaw)*zoom)
	camera.position = player.position+offset
	camera.look_at(player.position+Vector3.UP*1.2)
	if not started or hp<=0: return
	cooldown=maxf(0,cooldown-delta)
	dash_time=maxf(0,dash_time-delta)
	mp=minf(100,mp+delta*2)
	var input := stick
	input.x += float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	input.y += float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var move := Vector3(input.x,0,input.y).rotated(Vector3.UP,yaw).limit_length()
	if in_safe_zone():
		auto=false
		target=null
		hp=minf(100.0,hp+delta*6.0)
		mp=minf(100.0,mp+delta*4.0)
	if auto:
		if not is_instance_valid(target): choose_target()
		if is_instance_valid(target):
			var diff := target.position-player.position
			if diff.length()>2.2: move=Vector3(diff.x,0,diff.z).normalized()
			else: attack(0)
		collect()
	var speed := 8.0 if run_mode else 4.5
	if dash_time>0: speed=18
	player.velocity.x=move.x*speed
	player.velocity.z=move.z*speed
	if move.length()>0.02: player_visual.rotation.y=atan2(move.x,move.z)
	if not player.is_on_floor(): player.velocity.y-=20*delta
	elif jump_requested: player.velocity.y=8
	jump_requested=false
	player.move_and_slide()
	player.position.x=clampf(player.position.x,-40,40)
	player.position.z=clampf(player.position.z,-40,40)
	var safe := in_safe_zone()
	if safe:
		auto=false
		target=null
	for n in enemies:
		var home: Vector3 = n.get_meta("home")
		if is_safe_position(n.position, 0.6):
			n.position=home
			continue
		if safe:
			var returning := n.position.move_toward(home,delta*2.5)
			if not is_safe_position(returning,0.6): n.position=returning
			continue
		var diff := player.position-n.position
		if diff.length()<10 and diff.length()>1.6:
			var next := n.position+Vector3(diff.x,0,diff.z).normalized()*delta*1.5
			if not is_safe_position(next,0.6): n.position=next
		elif diff.length()<=1.6: hp=maxf(0,hp-delta*4)
