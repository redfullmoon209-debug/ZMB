extends SceneTree

func _initialize(): call_deferred("run")

func run():
	var splash := preload("res://studio_splash.gd").new()
	root.add_child(splash)
	assert(splash.logo.texture.get_width()==1500)
	assert(splash.audio.stream.data.size()==66150)
	splash._process(1.1)
	assert(splash.played and splash.shine.get_shader_parameter("visibility")>0.9)
	splash._process(3.0)
	await process_frame
	await process_frame
	assert(not is_instance_valid(splash))
	print("PASS: studio logo, audio, sweep and automatic transition")
	quit()
