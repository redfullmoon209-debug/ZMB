extends Node3D

const HUD = preload("res://hud.gd")
const Catalog = preload("res://item_catalog.gd")
const SAFE_HALF := 13.0
const GATE_HALF := 3.0
const RESPAWN_POINT := Vector3.ZERO
var player: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var enemies: Array[Node3D] = []
var demo_players: Array[Node3D] = []
var follow_player: Node3D
var loot: Array[Node3D] = []
var target: Node3D
var hp := 100.0
var mp := 100.0
var xp := 0
var level := 1
var coins := 0
var items: Array[String] = []
var equipment: Dictionary = {}
var profile_path := ""

func bonus(stat: String) -> float:
	var sum := 0.0
	for id in equipment.values(): sum+=float(Catalog.describe(id).get(stat,0))
	return sum

func max_hp() -> float: return 100.0+bonus("hp")
func max_mp() -> float: return 100.0+bonus("mp")
func attack_power() -> float: return gm_attack_power+bonus("attack")
func defense_power() -> float: return gm_defense+bonus("defense")

func equip_item(index: int, slot: String) -> bool:
	if index<0 or index>=items.size(): return false
	var id := items[index]
	if slot not in Catalog.describe(id).slots: return false
	items.remove_at(index)
	if equipment.has(slot): items.append(equipment[slot])
	equipment[slot]=id
	hp=minf(hp,max_hp()); mp=minf(mp,max_mp())
	ui.trade_selected.clear(); ui.market_selected=-1
	save_profile()
	return true

func unequip_item(slot: String) -> bool:
	if not equipment.has(slot) or items.size()>=48: return false
	items.append(equipment[slot]); equipment.erase(slot)
	hp=minf(hp,max_hp()); mp=minf(mp,max_mp())
	ui.trade_selected.clear(); ui.market_selected=-1
	save_profile()
	return true

func save_profile():
	if profile_path.is_empty() or not started: return
	var cfg := ConfigFile.new()
	for key in ["items","equipment","coins","xp","level","monsters_defeated","shards_collected","quest_claimed"]:
		cfg.set_value("character",key,get(key))
	cfg.save(profile_path)

func load_profile(path: String):
	profile_path=path
	var cfg := ConfigFile.new()
	if cfg.load(path)!=OK: return
	items.assign(cfg.get_value("character","items",[]))
	equipment=cfg.get_value("character","equipment",{})
	for key in ["coins","xp","level","monsters_defeated","shards_collected","quest_claimed"]:
		set(key,cfg.get_value("character",key,get(key)))
	hp=max_hp(); mp=max_mp()
var auto := false
var run_mode := false
var weapon := 0
var cooldown := 0.0
var yaw := 0.0
var pitch := deg_to_rad(28.0)
var zoom := 10.0
var camera_sensitivity := 1.0
var zoom_sensitivity := 1.0
var stick_deadzone := 0.06
var auto_hp_threshold := 0
var auto_mp_threshold := 0
var auto_loot := true
var auto_potion_cooldown := 0.0
var nearest_target_only := false
var sun_light: DirectionalLight3D
var camera_arm_distance := -1.0
var camera_follow := false
var follow_input_active := false
var follow_input_yaw := 0.0
var stick := Vector2.ZERO
var dash_time := 0.0
var jump_requested := false
var started := false
var male := true
var character_name := "Warrior"
var player_visual: Node3D
var attack_anim: Tween
var attack_pose_count := 0
var critical_chance := 0.10
const CRITICAL_MULTIPLIER := 1.5
var session_started_msec := -1
var previous_play_seconds := 0
var first_play_unix := 0
var playtime_save_timer := 0.0
var monsters_defeated := 0
var gm_test_enabled := false
var gm_target: Node3D
var gm_attack_power := 15.0
var gm_defense := 0.0
var gm_move_multiplier := 1.0
var gm_attack_multiplier := 1.0
var gm_invincible := false
var gm_invisible := false
var gm_logs: Array[String] = []
var gm_event_active := false
var gm_announcement := ""
var shards_collected := 0
var quest_claimed: Dictionary = {}
var daily_bosses := 0
var daily_day := ""
var daily_claimed := false
var daily_config := ConfigFile.new()
var playtime_config := ConfigFile.new()

func gm_allowed() -> bool:
	# Offline demo only. Real account authorization must never use this flag.
	return gm_test_enabled and bool(ProjectSettings.get_setting("zmb/offline_gm_test",false))

func gm_execute(command: String, value: float=0, item: String="") -> bool:
	if not gm_allowed() or not started: return false
	var locked := is_instance_valid(gm_target)
	var amount := int(value)
	match command:
		"gold":
			if locked: return false
			coins=clampi(coins+amount,0,100000000)
		"exp":
			if locked: return false
			var total:=clampi((level-1)*100+xp+amount,0,99999)
			level=int(total/100.0)+1
			xp=total%100
		"level":
			if locked: return false
			level=clampi(level+amount,1,1000)
		"hp":
			if locked: gm_target.set_meta("hp",clampf(float(gm_target.get_meta("hp"))+value,0,40+80*int(gm_target.get_meta("tier"))))
			else: hp=clampf(hp+value,0,max_hp())
		"mp":
			if locked: return false
			mp=clampf(mp+value,0,max_mp())
		"attack":
			if locked: return false
			gm_attack_power=clampf(gm_attack_power+value,0,100000)
		"defense":
			if locked: return false
			gm_defense=clampf(gm_defense+value,0,100000)
		"move_speed":
			if locked: return false
			gm_move_multiplier=clampf(value,0.25,5)
		"attack_speed":
			if locked: return false
			gm_attack_multiplier=clampf(value,0.25,5)
		"item":
			if locked or item not in ["HP Potion","MP Potion","Spirit shard"]: return false
			if amount>0:
				if items.size()+amount>48: return false
				for i in range(amount): items.append(item)
			else:
				if items.count(item)<-amount: return false
				for i in range(-amount): items.erase(item)
			if is_instance_valid(ui):
				ui.trade_selected.clear()
				ui.market_selected=-1
		"warp":
			var points: Array[Vector3]=[Vector3.ZERO,Vector3(0,0,-11),Vector3(11,0,0),Vector3(0,0,11),Vector3(-11,0,0),Vector3(0,0,-24),Vector3(0,0,-32),Vector3(0,0,-39)]
			if amount<0 or amount>=points.size(): return false
			player.position=points[amount]
			player.velocity=Vector3.ZERO
		"warp_target":
			if not locked: return false
			player.position=gm_target.position+Vector3(0,0,2)
			player.velocity=Vector3.ZERO
		"kill":
			if locked:
				gm_target.set_meta("gm_saved_hp",gm_target.get_meta("hp"))
				gm_target.set_meta("hp",0.0)
				enemies.erase(gm_target)
				gm_target.hide()
				if target==gm_target: target=null
			else: hp=0;auto=false
		"revive":
			if locked:
				gm_target.set_meta("hp",float(40+80*int(gm_target.get_meta("tier"))))
				if not enemies.has(gm_target): enemies.append(gm_target)
				gm_target.show()
			else: revive()
		"invincible":
			if locked: return false
			gm_invincible=value>0
		"invisible":
			if locked: return false
			gm_invisible=value>0
			player_visual.visible=not gm_invisible
		"spawn":
			if amount<0 or amount>2 or enemies.size()>=100: return false
			spawn_enemy(100+gm_logs.size(),amount)
		"remove":
			if not locked: return false
			enemies.erase(gm_target)
			if target==gm_target: target=null
			gm_target.queue_free()
			gm_target=null
		"event": gm_event_active=value>0
		"announce":
			if item.strip_edges().is_empty(): return false
			gm_announcement=item.strip_edges().left(180)
		_: return false
	gm_logs.push_front("%s UTC | %s | %s | %s"%[Time.get_datetime_string_from_system(true),command,str(value),item.left(180)])
	if gm_logs.size()>100: gm_logs.resize(100)
	return true

func session_seconds() -> int:
	return 0 if session_started_msec<0 else int((Time.get_ticks_msec()-session_started_msec)/1000.0)

func total_play_seconds() -> int:
	return previous_play_seconds+session_seconds()

func save_playtime():
	save_profile()
	if session_started_msec<0: return
	playtime_config.set_value("playtime","seconds",total_play_seconds())
	playtime_config.set_value("playtime","first_play_unix",first_play_unix)
	playtime_config.save("user://zmb_playtime.cfg")

func _notification(what: int):
	if what==NOTIFICATION_WM_CLOSE_REQUEST or what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED:
		save_playtime()

func _ready():
	gm_test_enabled=bool(ProjectSettings.get_setting("zmb/offline_gm_test",false))
	daily_config.load("user://zmb_daily.cfg")
	daily_day=str(daily_config.get_value("daily","day",""))
	daily_bosses=int(daily_config.get_value("daily","bosses",0))
	daily_claimed=bool(daily_config.get_value("daily","claimed",false))
	refresh_daily()
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
	sun_light=sun
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
	if gm_test_enabled:
		spawn_demo_player(Vector3(1.8,0,-3.8),"Training Ally")
		spawn_demo_player(Vector3(1.8,0,-17.5),"Training Rival")
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
		if side<0:
			box(Vector3(-0.46,1.05,0),Vector3(0.2,0.65,0.24),color,n)
	var arm := Node3D.new()
	arm.name="SwordArm"
	n.add_child(arm)
	arm.position=Vector3(0.46,1.35,0)
	box(Vector3(0,-0.30,0),Vector3(0.2,0.65,0.24),color,arm)
	box(Vector3(0.09,-0.50,0.1),Vector3(0.12,0.95,0.12),Color("aebac3"),arm)
	return n

func spawn_enemy(i: int, forced_tier: int=-1):
	var n := Node3D.new()
	add_child(n)
	var tier := forced_tier if forced_tier>=0 else (2 if i==11 else (1 if i%4==0 else 0))
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
	if session_started_msec<0:
		playtime_config.load("user://zmb_playtime.cfg")
		previous_play_seconds=maxi(0,int(playtime_config.get_value("playtime","seconds",0)))
		first_play_unix=int(playtime_config.get_value("playtime","first_play_unix",0))
		if first_play_unix<=0: first_play_unix=int(Time.get_unix_time_from_system())
		session_started_msec=Time.get_ticks_msec()
		save_playtime()
	male = is_male
	player_visual.scale = Vector3.ONE if male else Vector3(0.85,0.94,0.85)
	player_visual.rotation.y = PI
	started = true

func choose_target():
	if in_safe_zone():
		target=null
		return
	var sorted := enemies.filter(func(n): return is_instance_valid(n))
	sorted.sort_custom(func(a,b): return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
	if sorted.is_empty():
		return
	target = sorted[0] if nearest_target_only else sorted[(sorted.find(target)+1)%sorted.size()]

func spawn_demo_player(pos: Vector3, display_name: String):
	var n := Node3D.new()
	add_child(n)
	n.position=pos
	n.set_meta("demo_player",true)
	n.set_meta("display_name",display_name)
	n.set_meta("hp",100.0)
	n.set_meta("max_hp",100.0)
	figure(n,Color("416b9b"))
	var tag := Label3D.new()
	tag.text=display_name+" [TEST]"
	tag.position=Vector3(0,2.2,0)
	tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size=32
	tag.outline_size=6
	tag.modulate=Color("a9dbff")
	n.add_child(tag)
	demo_players.append(n)

func is_demo_target(n: Node3D) -> bool:
	return is_instance_valid(n) and n.get_meta("demo_player",false)

func choose_player_target():
	var candidates := demo_players.filter(func(n): return is_instance_valid(n) and n.get_meta("hp",0)>0 and is_safe_position(n.position)==in_safe_zone())
	candidates.sort_custom(func(a,b): return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
	if candidates.is_empty():
		target=null
		return
	target=candidates[0] if nearest_target_only else candidates[(candidates.find(target)+1)%candidates.size()]
	auto=false
	if follow_player!=target: follow_player=null

func toggle_player_follow():
	if not is_demo_target(target): return
	if follow_player==target: follow_player=null
	else:
		follow_player=target
		auto=false

func select_target_at(pos: Vector2):
	var candidates: Array[Node3D]=demo_players.duplicate()
	if not in_safe_zone(): candidates.append_array(enemies)
	var nearest := 65.0
	for n in candidates:
		if not is_instance_valid(n) or n.get_meta("hp",0)<=0 or is_safe_position(n.position)!=in_safe_zone(): continue
		if camera.is_position_behind(n.position+Vector3.UP): continue
		var d := camera.unproject_position(n.position+Vector3.UP).distance_to(pos)
		if d<nearest:
			nearest=d
			target=n
	if is_demo_target(target): auto=false
	if follow_player!=target: follow_player=null

func play_attack_pose(skill: int):
	var arm := player_visual.get_node("SwordArm") as Node3D
	if attack_anim and attack_anim.is_valid(): attack_anim.kill()
	attack_pose_count+=1
	arm.rotation=Vector3.ZERO
	var windup: Vector3 = [Vector3(-0.95,0,-0.8),Vector3(-1.3,-1.2,-0.4),Vector3(-0.5,0,-0.5),Vector3(-2.5,0,0)][skill]
	var strike: Vector3 = [Vector3(-1.8,0.8,0.55),Vector3(-1.45,2.7,0.5),Vector3(-1.55,0,0),Vector3(-0.65,0,0)][skill]
	attack_anim=create_tween().set_trans(Tween.TRANS_SINE)
	attack_anim.tween_property(arm,"rotation",windup,0.10/gm_attack_multiplier)
	attack_anim.tween_property(arm,"rotation",strike,0.14/gm_attack_multiplier)
	attack_anim.tween_property(arm,"rotation",Vector3.ZERO,0.18/gm_attack_multiplier)

func show_damage_number(pos: Vector3, amount: int, critical: bool):
	var number := Label3D.new()
	number.text=str(amount)
	number.font=preload("res://assets/fonts/NotoSansThai-Regular.ttf")
	number.font_size=76 if critical else 58
	number.outline_size=12
	number.outline_modulate=Color("111318")
	number.modulate=Color("ff4149") if critical else Color.WHITE
	number.pixel_size=0.008
	number.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	number.no_depth_test=true
	number.visible=false # Screen-space HUD handles legibility at every zoom.
	number.set_meta("damage_number",true)
	number.set_meta("critical",critical)
	add_child(number)
	number.position=pos
	ui.add_damage_overlay(number)
	var animation := create_tween().set_parallel(true)
	animation.tween_property(number,"position",pos+Vector3.UP*1.0,0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(number,"modulate:a",0.0,0.35).set_delay(0.5)
	animation.tween_property(number,"outline_modulate:a",0.0,0.35).set_delay(0.5)
	animation.chain().tween_callback(number.queue_free)

func deal_damage(victim: Node3D, skill: int):
	var critical := randf()<clampf(critical_chance+bonus("crit"),0,1)
	var amount := maxi(0,roundi((attack_power()+skill*7)*(CRITICAL_MULTIPLIER if critical else 1.0)))
	victim.set_meta("hp",maxf(0,float(victim.get_meta("hp"))-amount))
	if amount>0: show_damage_number(victim.position+Vector3.UP*(2.35*victim.scale.y),amount,critical)

func attack(skill: int):
	if not started or hp<=0 or cooldown>0 or skill<0 or skill>3:
		return
	if mp < skill*5: return
	# Preview the swing even without an enemy; safe zones never take damage.
	cooldown = (0.45+skill*0.2)/gm_attack_multiplier
	play_attack_pose(skill)
	if in_safe_zone(): return
	if not is_instance_valid(target): choose_target()
	if not is_instance_valid(target): return
	if is_safe_position(target.position): return
	var ranges := [2.7,5.5,12.0]
	if player.position.distance_to(target.position)>ranges[weapon]+skill: return
	var direction := target.position-player.position
	if Vector2(direction.x,direction.z).length()>0.01:
		player_visual.rotation.y=atan2(direction.x,direction.z)
	mp -= skill*5
	if is_demo_target(target):
		var dummy := target
		deal_damage(dummy,skill)
		if dummy.get_meta("hp")<=0:
			target=null
			dummy.hide()
			get_tree().create_timer(3).timeout.connect(func():
				if is_instance_valid(dummy):
					dummy.set_meta("hp",100.0)
					dummy.show())
		return
	var hits := [target]
	if skill==3:
		for n in enemies:
			if n!=target and not is_safe_position(n.position) and n.position.distance_to(target.position)<3: hits.append(n)
	for n in hits:
		deal_damage(n,skill)
		if n.get_meta("hp")<=0:
			monsters_defeated+=1
			if int(n.get_meta("tier"))==2:
				refresh_daily()
				daily_bosses+=1
				save_daily()
			var drop := box(n.position+Vector3.UP*0.25,Vector3(0.5,0.5,0.5),Color("e7c46d"),self)
			drop.set_meta("item",Catalog.drop(int(n.get_meta("tier"))))
			(drop.material_override as StandardMaterial3D).albedo_color=Catalog.describe(drop.get_meta("item")).color
			loot.append(drop)
			xp += 25
			if xp>=100:
				level+=1
				xp-=100
			enemies.erase(n)
			n.queue_free()
			if n==target: target=null
			var spawn_index: int = n.get_meta("spawn_index")
			var spawn_tier: int=int(n.get_meta("tier"))
			get_tree().create_timer(5).timeout.connect(func(): spawn_enemy(spawn_index,spawn_tier))
			save_profile()

func collect(radius: float=4.0):
	for d in loot.duplicate():
		var offset: Vector3 = player.position-d.position
		if Vector2(offset.x,offset.z).length()<radius and absf(offset.y)<1.5 and items.size()<48:
			var id: String=d.get_meta("item","Spirit shard")
			items.append(id)
			if id=="Spirit shard": shards_collected+=1
			coins+=5
			loot.erase(d)
			d.queue_free()
			save_profile()

func save_daily():
	daily_config.set_value("daily","day",daily_day)
	daily_config.set_value("daily","bosses",daily_bosses)
	daily_config.set_value("daily","claimed",daily_claimed)
	daily_config.save("user://zmb_daily.cfg")

func refresh_daily():
	var today := Time.get_date_string_from_system(true)
	if today!=daily_day:
		daily_day=today
		daily_bosses=0
		daily_claimed=false
		save_daily()

func quest_progress(id: String) -> int:
	match id:
		"main": return monsters_defeated
		"side": return shards_collected
		"daily": refresh_daily();return daily_bosses
	return 0

func quest_goal(id: String) -> int:
	return int({"main":30,"side":10,"daily":3}.get(id,0))

func quest_reward(id: String) -> int:
	return int({"main":100,"side":50,"daily":150}.get(id,0))

func is_quest_claimed(id: String) -> bool:
	if id=="daily": refresh_daily();return daily_claimed
	return quest_claimed.has(id)

func claim_quest(id: String) -> bool:
	if not started or quest_goal(id)<=0 or is_quest_claimed(id) or quest_progress(id)<quest_goal(id): return false
	if id=="daily":
		daily_claimed=true
		save_daily()
	else: quest_claimed[id]=true
	coins+=quest_reward(id)
	return true

func revive():
	if attack_anim and attack_anim.is_valid(): attack_anim.kill()
	player_visual.get_node("SwordArm").rotation=Vector3.ZERO
	cooldown=0.0
	hp=max_hp()
	mp=max_mp()
	player.position=RESPAWN_POINT
	player.velocity=Vector3.ZERO
	target=null
	follow_player=null
	auto=false
	follow_input_active=false
	player_visual.rotation.y=PI

func set_camera_follow(enabled: bool):
	camera_follow=enabled
	follow_input_active=false

func rotate_camera(relative: Vector2):
	# Vertical orbit is available in both modes. Follow mode owns horizontal
	# heading, so dragging sideways never breaks the behind-character lock.
	if not camera_follow:
		yaw=wrapf(yaw-relative.x*0.007*camera_sensitivity,-PI,PI)
	pitch=clampf(pitch-relative.y*0.007*camera_sensitivity,deg_to_rad(-8.0),deg_to_rad(78.0))

func movement_vector(input: Vector2) -> Vector3:
	if input.length()<stick_deadzone: input=Vector2.ZERO
	var movement_yaw := yaw
	if camera_follow:
		# Keep a held joystick's reference stable while the camera turns behind
		# the player; otherwise holding sideways would make the player circle.
		if input.length()<=0.06:
			follow_input_active=false
		elif not follow_input_active:
			follow_input_yaw=yaw
			follow_input_active=true
		if follow_input_active: movement_yaw=follow_input_yaw
	return Vector3(input.x,0,input.y).rotated(Vector3.UP,movement_yaw).limit_length()

func update_camera(delta: float):
	if camera_follow and started:
		var desired_yaw := wrapf(player_visual.rotation.y+PI,-PI,PI)
		yaw=lerp_angle(yaw,desired_yaw,1.0-exp(-8.0*delta))
	var focus := player.position+Vector3.UP*1.2
	var horizontal := cos(pitch)*zoom
	var offset := Vector3(sin(yaw)*horizontal,sin(pitch)*zoom,cos(yaw)*horizontal)
	var desired := focus+offset
	desired.y=maxf(0.5,desired.y)
	# Clip against town walls, rather than placing the camera inside them.
	var ray := PhysicsRayQueryParameters3D.create(focus,desired)
	ray.exclude=[player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	var allowed_distance := focus.distance_to(desired)
	if not hit.is_empty():
		var hit_position: Vector3=hit.position
		allowed_distance=minf(allowed_distance,maxf(0.6,focus.distance_to(hit_position)-0.25))
	# Retract immediately to avoid clipping, but recover smoothly when a
	# wall edge leaves the ray; no sudden jump back to full zoom distance.
	if camera_arm_distance<0.0 or allowed_distance<camera_arm_distance:
		camera_arm_distance=allowed_distance
	else:
		camera_arm_distance=lerpf(camera_arm_distance,allowed_distance,1.0-exp(-9.0*delta))
	desired=focus+(desired-focus).normalized()*camera_arm_distance
	camera.position=desired
	camera.look_at(focus)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): rotate_camera(event.relative)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom=maxf(4,zoom-zoom_sensitivity)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom=minf(16,zoom+zoom_sensitivity)
		if event.button_index==MOUSE_BUTTON_LEFT: select_target_at(event.position)
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
	if started:
		playtime_save_timer+=delta
		if playtime_save_timer>=10.0:
			playtime_save_timer=0.0
			save_playtime()
	if not started or hp<=0:
		update_camera(delta)
		return
	cooldown=maxf(0,cooldown-delta)
	auto_potion_cooldown=maxf(0,auto_potion_cooldown-delta)
	if not in_safe_zone() and auto_potion_cooldown<=0:
		if auto_hp_threshold>0 and hp<=max_hp()*auto_hp_threshold/100.0:
			hp=minf(max_hp(),hp+35)
			auto_potion_cooldown=5.0
		elif auto_mp_threshold>0 and mp<=max_mp()*auto_mp_threshold/100.0:
			mp=minf(max_mp(),mp+35)
			auto_potion_cooldown=5.0
	dash_time=maxf(0,dash_time-delta)
	mp=minf(max_mp(),mp+delta*2)
	var input := stick
	input.x += float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
	input.y += float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
	var move := movement_vector(input)
	if is_instance_valid(follow_player):
		if move.length()>0.02 or auto or follow_player!=target or follow_player.get_meta("hp",0)<=0 or is_safe_position(follow_player.position)!=in_safe_zone():
			follow_player=null
		else:
			var follow_delta := follow_player.position-player.position
			follow_delta.y=0
			if follow_delta.length()>2.0: move=follow_delta.normalized()
	if in_safe_zone():
		auto=false
		if not is_demo_target(target) or not is_safe_position(target.position): target=null
		hp=minf(max_hp(),hp+delta*6.0)
		mp=minf(max_mp(),mp+delta*4.0)
	if auto:
		if is_demo_target(target): target=null
		if not is_instance_valid(target): choose_target()
		if is_instance_valid(target):
			var diff := target.position-player.position
			if diff.length()>2.2: move=Vector3(diff.x,0,diff.z).normalized()
			else: attack(0)
		if auto_loot: collect()
	var speed := (8.0 if run_mode else 4.5)*gm_move_multiplier
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
	# Walking across the drop collects it even when auto-hunt is disabled.
	collect(1.5)
	var safe := in_safe_zone()
	if safe:
		auto=false
		if not is_demo_target(target) or not is_safe_position(target.position): target=null
	elif is_demo_target(target) and is_safe_position(target.position): target=null
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
		if gm_invisible: continue
		if diff.length()<10 and diff.length()>1.6:
			var next := n.position+Vector3(diff.x,0,diff.z).normalized()*delta*1.5
			if not is_safe_position(next,0.6): n.position=next
		elif diff.length()<=1.6 and not gm_invincible: hp=maxf(0,hp-delta*maxf(0,4-defense_power()))
	update_camera(delta)
