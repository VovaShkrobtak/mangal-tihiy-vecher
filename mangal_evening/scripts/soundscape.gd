extends Node
## Persistent evening ambience and one-shot sound effects.

var state = null
var detail_player: AudioStreamPlayer
var detail_timer := 3.0
var rng := RandomNumberGenerator.new()
var ambient_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer
var ambient_volume := 0.80

func _ready() -> void:
	rng.randomize()
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "EveningAmbience"
	ambient_player.bus = "Master"
	add_child(ambient_player)
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "Foley"
	effects_player.bus = "Master"
	add_child(effects_player)
	detail_player = AudioStreamPlayer.new()
	detail_player.name = "LivingDetails"
	detail_player.bus = "Master"
	add_child(detail_player)
	var ambience: AudioStream = load("res://audio/night_ambience.wav")
	if ambience is AudioStreamWAV:
		var wav := ambience as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
	ambient_player.stream = ambience

func configure(loudness: float) -> void:
	set_ambient_volume(loudness)
	if ambient_player.stream != null and not ambient_player.playing:
		ambient_player.play()

func set_ambient_volume(loudness: float) -> void:
	ambient_volume = clampf(loudness, 0.0, 1.0)
	# At 0.8 the ambience is ~-10 dB instead of the old inaudible -27 dB.
	ambient_player.volume_db = linear_to_db(maxf(0.0001, ambient_volume * 0.40))

func play_effect(name: String) -> void:
	var path := "res://audio/" + name
	if not ResourceLoader.exists(path):
		push_warning("Missing Foley sound: " + path)
		return
	effects_player.stream = load(path)
	effects_player.volume_db = -9.0
	effects_player.play()

func _process(delta: float) -> void:
	if ambient_player.stream != null and not ambient_player.playing:
		ambient_player.play()
	if state == null:
		return
	detail_timer -= delta
	if detail_timer > 0.0:
		return
	detail_timer = rng.randf_range(3.5, 7.0)
	if detail_player.playing or float(state.coals) < 8.0:
		return
	var clip := "coals.wav"
	var loudness := -17.0
	if String(state.current_food) != "" and rng.randf() < 0.55:
		clip = "sizzle.wav"
		loudness = -15.0
	var path := "res://audio/" + clip
	if ResourceLoader.exists(path):
		detail_player.stream = load(path)
		detail_player.volume_db = loudness
		detail_player.pitch_scale = rng.randf_range(0.94, 1.06)
		detail_player.play()
