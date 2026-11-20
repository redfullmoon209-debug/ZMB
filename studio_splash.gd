extends Control

const DURATION := 3.8
var elapsed := 0.0
var logo: TextureRect
var backdrop: ColorRect
var shine: ShaderMaterial
var audio: AudioStreamPlayer
var played := false

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index=100
	mouse_filter=Control.MOUSE_FILTER_STOP
	var black := ColorRect.new()
	backdrop=black
	black.color=Color.BLACK
	add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter=Control.MOUSE_FILTER_IGNORE
	logo=TextureRect.new()
	logo.texture=preload("res://assets/branding/cross_studio.webp")
	logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.offset_left=165; logo.offset_right=-165
	logo.offset_top=180; logo.offset_bottom=-180
	var shader := Shader.new()
	shader.code="""shader_type canvas_item;
uniform float sweep = -0.5;
uniform float visibility = 0.0;
void fragment(){
  vec4 source = texture(TEXTURE, UV);
  float d = UV.x + (UV.y - 0.5)*0.18 - sweep;
  float beam = exp(-d*d*210.0)*0.56 + exp(-d*d*6800.0)*0.42;
  COLOR = vec4(mix(source.rgb,vec3(1.0,0.97,0.91),beam), source.a*visibility);
}"""
	shine=ShaderMaterial.new()
	shine.shader=shader
	logo.material=shine
	audio=AudioStreamPlayer.new()
	audio.stream=make_sound()
	add_child(audio)
	if AudioServer.get_bus_index("System")>=0: audio.bus="System"

func make_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var bytes := PackedByteArray()
	var frames := 33075
	bytes.resize(frames*2)
	var rng := RandomNumberGenerator.new()
	rng.seed=4187
	var filtered := 0.0
	for i in range(frames):
		var t := float(i)/22050.0
		var envelope := sin(PI*minf(t/1.5,1.0))
		filtered=lerpf(filtered,rng.randf_range(-1,1),0.14)
		var whoosh := filtered*envelope*0.32
		var bell := (sin(TAU*330*t)+0.36*sin(TAU*660*t)+0.18*sin(TAU*1037*t))*exp(-4.0*t)*minf(t*35,1.0)*0.19
		bytes.encode_s16(i*2,roundi(clampf(whoosh+bell,-1,1)*32767))
	stream.data=bytes
	return stream

func _process(delta: float):
	elapsed+=delta
	shine.set_shader_parameter("visibility",smoothstep(0.12,0.9,elapsed)*(1.0-smoothstep(2.95,DURATION,elapsed)))
	shine.set_shader_parameter("sweep",lerpf(-0.30,1.30,clampf((elapsed-0.8)/1.45,0,1)))
	backdrop.modulate.a=1.0-smoothstep(3.35,DURATION,elapsed)
	if elapsed>=0.8 and not played:
		played=true
		audio.play()
	if elapsed>=DURATION: queue_free()
