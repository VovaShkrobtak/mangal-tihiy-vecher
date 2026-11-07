extends Node
## Radio tuner: continuous WAV playback, station search, static and automatic recovery.
## Deliberately independent of the HUD, save file and soundscape.

const Data = preload("res://scripts/data.gd")
const STATIONS = Data.STATIONS
const MAX_DETUNE := 0.34

var is_on := true
var frequency := 93.7
var volume := 0.75
var active_station := -1
var reception := 0.0
var error_text := ""
var music_player: AudioStreamPlayer
var static_player: AudioStreamPlayer
var _health_check := 0.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	music_player.bus = "Master"
	add_child(music_player)
	static_player = AudioStreamPlayer.new()
	static_player.name = "Static"
	static_player.bus = "Master"
	add_child(static_player)
	static_player.stream = _load_loop("radio_static.wav")

func configure(power: bool, mhz: float, loudness: float) -> void:
	is_on = power
	frequency = clampf(snappedf(mhz, 0.1), 87.5, 108.0)
	volume = clampf(loudness, 0.0, 1.0)
	apply_tuning()

func set_power(power: bool) -> void:
	is_on = power
	apply_tuning()

func set_frequency(mhz: float) -> void:
	frequency = clampf(snappedf(mhz, 0.1), 87.5, 108.0)
	apply_tuning()

func set_volume(loudness: float) -> void:
	volume = clampf(loudness, 0.0, 1.0)
	_update_mix()

func tune_preset(index: int) -> void:
	if index >= 0 and index < STATIONS.size():
		set_frequency(float(STATIONS[index]["freq"]))

func test_station() -> void:
	# This intentionally overrides an old muted/off save so playback can be checked.
	is_on = true
	volume = maxf(volume, 0.75)
	set_frequency(93.7)
	if music_player.stream != null:
		music_player.stop()
		music_player.play()

func _load_loop(file_name: String) -> AudioStream:
	var path := "res://audio/" + file_name
	var stream: AudioStream = load(path)
	if stream == null:
		error_text = "Нет аудиофайла: " + file_name
		push_warning(error_text)
		return null
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		# Explicit sample-based loop end; do not depend on imported WAV metadata.
		wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
	return stream

func apply_tuning() -> void:
	if not is_on:
		active_station = -1
		reception = 0.0
		music_player.stop()
		static_player.stop()
		return
	var nearest := -1
	var best := 100.0
	for i in range(STATIONS.size()):
		var diff: float = absf(frequency - float(STATIONS[i]["freq"]))
		if diff < best:
			best = diff
			nearest = i
	var next_station := nearest if best <= MAX_DETUNE else -1
	reception = clampf(1.0 - best / MAX_DETUNE, 0.0, 1.0)
	if next_station != active_station or (next_station >= 0 and music_player.stream == null):
		active_station = next_station
		music_player.stop()
		if active_station >= 0:
			music_player.stream = _load_loop(String(STATIONS[active_station]["file"]))
			if music_player.stream != null:
				music_player.play()
		else:
			music_player.stream = null
	if static_player.stream != null and not static_player.playing:
		static_player.play()
	_update_mix()

func _update_mix() -> void:
	if not is_on:
		return
	# The old build attenuated the radio unnecessarily. Keep it louder than ambience.
	music_player.volume_db = linear_to_db(maxf(0.0001, volume * reception * 0.95))
	static_player.volume_db = linear_to_db(maxf(0.0001, volume * (0.012 + (1.0 - reception) * 0.16)))

func _process(delta: float) -> void:
	_health_check += delta
	if _health_check < 0.75:
		return
	_health_check = 0.0
	if not is_on:
		return
	# Recover from drivers or imported streams that stopped after a loop/scene resume.
	if active_station >= 0 and music_player.stream != null and not music_player.playing:
		music_player.play()
	if static_player.stream != null and not static_player.playing:
		static_player.play()

func station_description() -> String:
	if not is_on:
		return "Приёмник выключен."
	if active_station < 0:
		return "Ш-ш-ш... Между станциями только помехи."
	if music_player.stream == null:
		return "Радио не загрузилось: проверь audio/*.wav"
	var station: Dictionary = STATIONS[active_station]
	return "В ЭФИРЕ: %s — %s | сигнал %d%%" % [station["name"], station["genre"], int(reception * 100.0)]
