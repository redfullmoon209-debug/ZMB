extends Control

var game: Node3D
const WORLD_HALF := 45.0

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true

func map_point(p: Vector3) -> Vector2:
	return size*0.5+Vector2(p.x,p.z)*(minf(size.x,size.y)-12.0)/(WORLD_HALF*2.0)

func _process(_delta):
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("212a29e8"))
	if not is_instance_valid(game) or not is_instance_valid(game.player): return
	var start := map_point(Vector3(-45,0,-45))
	var end := map_point(Vector3(45,0,45))
	draw_rect(Rect2(start,end-start),Color("405348"))
	var village_start := map_point(Vector3(-13,0,-13))
	var village_end := map_point(Vector3(13,0,13))
	draw_rect(Rect2(village_start,village_end-village_start),Color("788b75"))
	draw_rect(Rect2(village_start,village_end-village_start),Color("aec3a9"),false,1.0)
	draw_line(map_point(Vector3(-19,0,0)),map_point(Vector3(19,0,0)),Color("b8ae95"),6)
	draw_line(map_point(Vector3(0,0,-19)),map_point(Vector3(0,0,19)),Color("b8ae95"),6)
	for x in [-8.0,8.0]:
		for z in [-7.0,7.0]:
			var a := map_point(Vector3(x-2.5,0,z-2.0))
			var b := map_point(Vector3(x+2.5,0,z+2.0))
			draw_rect(Rect2(a,b-a),Color("4a3d39"))
	for enemy in game.enemies:
		if not is_instance_valid(enemy): continue
		var tier: int=enemy.get_meta("tier",0)
		draw_circle(map_point(enemy.position),3.0 if tier==0 else 4.0,Color("e2a667") if tier==2 else Color("d77973"))
	var p := map_point(game.player.position)
	var heading: float=game.player_visual.rotation.y
	var direction := Vector2(sin(heading),cos(heading))
	var side := Vector2(-direction.y,direction.x)
	draw_circle(p,6.5,Color("172120"))
	draw_colored_polygon(PackedVector2Array([p+direction*8,p-direction*4+side*4,p-direction*4-side*4]),Color("f4faf2"))
	draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color("9aa8a4"),false,2)
	draw_string(ThemeDB.fallback_font,Vector2(size.x*0.5-5,15),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
