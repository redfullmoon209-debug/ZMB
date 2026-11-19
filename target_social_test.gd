extends SceneTree

func _initialize(): call_deferred("run")

func tap(pos: Vector2):
	var e:=InputEventScreenTouch.new()
	e.index=7
	e.position=pos
	e.pressed=true
	root.push_input(e,true)
	e=InputEventScreenTouch.new()
	e.index=7
	e.position=pos
	e.pressed=false
	root.push_input(e,true)

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	var h=world.ui
	world.choose_player_target()
	h.refresh_target_status(true)
	assert(h.target_portrait_image.visible and is_instance_valid(h.target_model))
	assert(h.target_menu_button.visible and not h.target_menu.visible)
	assert(is_equal_approx(h.target_menu_button.get_global_rect().get_center().x,h.target_portrait_art.get_global_rect().get_center().x))
	assert(h.target_menu_button.get_global_rect().position.y>=h.target_portrait_art.get_global_rect().end.y)
	assert(is_instance_valid(h.target_menu_icon.texture))
	for i in range(3):
		tap(h.target_menu_button.get_global_rect().get_center())
		assert(h.target_menu.visible)
		tap(h.target_actions[i+1].get_global_rect().get_center())
		assert(not h.target_menu.visible)
	assert(h.demo_friends.size()==1 and h.demo_party.size()==1 and h.demo_guild.size()==1)
	tap(h.target_menu_button.get_global_rect().get_center())
	tap(h.target_actions[4].get_global_rect().get_center())
	assert(h.selected_page=="Trade" and h.trade_partner=="Training Ally")
	h.close_page()
	tap(h.target_menu_button.get_global_rect().get_center())
	tap(h.target_actions[5].get_global_rect().get_center())
	assert(world.follow_player==world.target)
	var before: float=world.player.position.distance_to(world.target.position)
	for i in range(20): await physics_frame
	assert(world.player.position.distance_to(world.target.position)<before)
	world.stick=Vector2(1,0)
	await physics_frame
	await physics_frame
	assert(world.follow_player==null)
	world.target=null
	h.refresh_target_status(true)
	assert(not h.target_menu_button.visible and not h.target_menu.visible)
	print("PASS: target portrait, touch dropdown, demo social actions, trade and follow/manual cancel")
	quit()
