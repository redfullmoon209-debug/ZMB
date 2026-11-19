extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var world := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	world.begin(true)
	world.ui.close_page()
	world.items.assign(["Rare Sword","Epic Armor","Legendary Ring","Common Ring"])
	world.ui.open_page("Bag")
	await process_frame
	world.ui.show_item_details("Rare Sword",0)
	assert(world.ui.item_dialog.visible)
	world.ui.item_dialog.custom_action.emit("main")
	assert(world.attack_power()==27 and world.items.size()==3)
	assert(world.equip_item(0,"armor") and world.max_hp()==120 and world.defense_power()==4)
	assert(world.equip_item(0,"ring1") and world.equip_item(0,"ring2"))
	assert(is_equal_approx(world.bonus("crit"),0.06))
	assert(world.unequip_item("ring1") and world.items.size()==1)
	var path := "user://equipment_test_%d.cfg"%Time.get_ticks_usec()
	world.profile_path=path
	world.coins=99;world.level=5;world.xp=30
	world.save_profile()
	world.items.clear();world.equipment.clear();world.coins=0
	world.load_profile(path)
	assert(world.coins==99 and world.level==5 and world.xp==30)
	assert(world.equipment.size()==3 and world.items.size()==1 and world.max_hp()==120)
	world.profile_path=""
	DirAccess.remove_absolute(path)
	print("PASS: inventory detail UI, equip/unequip, stats and persistent profile roundtrip")
	quit()
