extends Control

var game: Node3D
const WORLD_HALF := 45.0
var map_zoom := 1.0
var circle_mask := PackedVector2Array()

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true

func map_point(p: Vector3) -> Vector2:
	var center := Vector2.ZERO
	if map_zoom>1.0 and is_instance_valid(game) and is_instance_valid(game.player):
		center=Vector2(game.player.position.x,game.player.position.z)
	return size*0.5+(Vector2(p.x,p.z)-center)*(minf(size.x,size.y)-12.0)*map_zoom/(WORLD_HALF*2.0)

func change_zoom(step: float):
	map_zoom=clampf(map_zoom+step,1.0,4.0)
	queue_redraw()

func map_rect(a: Vector2,b: Vector2,color: Color):
	var corners := PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
	for clipped in Geometry2D.intersect_polygons(corners,circle_mask):
		if clipped.size()>=3: draw_colored_polygon(clipped,color)

func inside_map(p: Vector2,margin: float=0.0) -> bool:
	return p.distance_to(size*0.5)<=minf(size.x,size.y)*0.5-5.0-margin

func _process(_delta):
	queue_redraw()

func _draw():
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.5-2.0
	draw_circle(center,radius,Color("212a29e8"),true,-1.0,true)
	circle_mask.clear()
	for i in range(96): circle_mask.append(center+Vector2.from_angle(TAU*i/96.0)*(radius-3.0))
	if not is_instance_valid(game) or not is_instance_valid(game.player): return
	var start := map_point(Vector3(-45,0,-45))
	var end := map_point(Vector3(45,0,45))
	map_rect(start,end,Color("405348"))
	var village_start := map_point(Vector3(-13,0,-13))
	var village_end := map_point(Vector3(13,0,13))
	map_rect(village_start,village_end,Color("788b75"))
	map_rect(map_point(Vector3(-19,0,-1.5)),map_point(Vector3(19,0,1.5)),Color("b8ae95"))
	map_rect(map_point(Vector3(-1.5,0,-19)),map_point(Vector3(1.5,0,19)),Color("b8ae95"))
	for x in [-8.0,8.0]:
		for z in [-7.0,7.0]:
			var a := map_point(Vector3(x-2.5,0,z-2.0))
			var b := map_point(Vector3(x+2.5,0,z+2.0))
			map_rect(a,b,Color("4a3d39"))
	for enemy in game.enemies:
		if not is_instance_valid(enemy): continue
		var tier: int=enemy.get_meta("tier",0)
		var dot := map_point(enemy.position)
		if inside_map(dot,4.0): draw_circle(dot,3.0 if tier==0 else 4.0,Color("e2a667") if tier==2 else Color("d77973"))
	var p := map_point(game.player.position)
	var heading: float=game.player_visual.rotation.y
	var direction := Vector2(sin(heading),cos(heading))
	var side := Vector2(-direction.y,direction.x)
	if not inside_map(p,8.0): p=center+(p-center).limit_length(radius-10.0)
	draw_circle(p,6.5,Color("172120"))
	draw_colored_polygon(PackedVector2Array([p+direction*8,p-direction*4+side*4,p-direction*4-side*4]),Color("f4faf2"))
	draw_arc(center,radius,0,TAU,96,Color("9aa8a4"),2.0,true)
	draw_string(ThemeDB.fallback_font,Vector2(size.x*0.5-5,15),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
