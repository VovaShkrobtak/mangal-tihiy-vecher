extends Node
## Persistent evening ambience and one-shot sound effects.

var ambient_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer
var ambient_volume := 0.80

func _ready() -> void:
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "EveningAmbience"
	ambient_player.bus = "Master"
	add_child(ambient_player)
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "Foley"
	effects_player.bus = "Master"
	add_child(effects_player)
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

func _process(_delta: float) -> void:
	if ambient_player.stream != null and not ambient_player.playing:
		ambient_player.play()
