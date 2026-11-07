extends Node
## Tuning, radio audio, analogue static, synthesized idents and fictional broadcast speech.
## Music and effects are offline. Speech uses the system Russian TTS voice when installed.

const Data = preload("res://scripts/data.gd")
const Programs = preload("res://scripts/radio_programs.gd")
const STATIONS = Data.STATIONS
const MIN_FREQ := 87.5
const MAX_FREQ := 108.0
const MAX_DETUNE := 0.42
const BUS_NAME := "VintageRadio"

var state = null
var is_on := true
var frequency := 93.7
var volume := 0.75
var active_station := -1
var reception := 0.0
var target_reception := 0.0
var error_text := ""
var music_player: AudioStreamPlayer
var static_player: AudioStreamPlayer
var jingle_player: AudioStreamPlayer
var music_streams: Array[AudioStream] = []
var jingles: Array[AudioStream] = []
var broadcast_text := ""
var broadcast_kind := ""
var broadcast_remaining := 0.0
var broadcast_count := 0
var break_timer := 5.0
var pending_speech := -1.0
var voice_active := false
var voice_elapsed := 0.0
var voice_timeout := 0.0
var voice_id := ""
var _rng := RandomNumberGenerator.new()
var _health_check := 0.0

func _ready() -> void:
	_rng.randomize()
	_install_speaker_filter()
	for station in STATIONS:
		music_streams.append(_load_loop(String(station["file"])))
	for i in range(STATIONS.size()):
		jingles.append(_build_jingle(i))
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	music_player.bus = BUS_NAME
	add_child(music_player)
	static_player = AudioStreamPlayer.new()
	static_player.name = "Static"
	static_player.bus = BUS_NAME
	add_child(static_player)
	static_player.stream = _load_loop("radio_static.wav")
	jingle_player = AudioStreamPlayer.new()
	jingle_player.name = "StationIdent"
	jingle_player.bus = BUS_NAME
	add_child(jingle_player)
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("ru")
		if not voices.is_empty():
			voice_id = voices[0]

func _install_speaker_filter() -> void:
	if AudioServer.get_bus_index(BUS_NAME) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS_NAME)
	AudioServer.set_bus_send(index, "Master")
	var high := AudioEffectHighPassFilter.new()
	high.cutoff_hz = 170.0
	var low := AudioEffectLowPassFilter.new()
	low.cutoff_hz = 3200.0
	AudioServer.add_bus_effect(index, high)
	AudioServer.add_bus_effect(index, low)

func configure(power: bool, mhz: float, loudness: float) -> void:
	is_on = power
	frequency = clampf(snappedf(mhz, 0.1), MIN_FREQ, MAX_FREQ)
	volume = clampf(loudness, 0.0, 1.0)
	apply_tuning(true)

func set_power(power: bool) -> void:
	if is_on == power:
		return
	is_on = power
	apply_tuning(true)

func set_frequency(mhz: float) -> void:
	var freq: float = clampf(snappedf(mhz, 0.1), MIN_FREQ, MAX_FREQ)
	if is_equal_approx(frequency, freq):
		return
	frequency = freq
	apply_tuning(false)

func set_volume(loudness: float) -> void:
	volume = clampf(loudness, 0.0, 1.0)
	_update_mix()

func tune_preset(index: int) -> void:
	if index >= 0 and index < STATIONS.size():
		set_frequency(float(STATIONS[index]["freq"]))

func test_station() -> void:
	is_on = true
	volume = maxf(volume, 0.75)
	frequency = 93.7
	apply_tuning(true)
	if music_player.stream != null:
		music_player.stop()
		music_player.play()
	_update_mix()

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
		wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
	return stream

func _build_jingle(station: int) -> AudioStreamWAV:
	# Tiny 3-note ident generated at runtime: no external music or Internet.
	var rate := 22050
	var length := 0.66
	var count: int = int(rate * length)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var roots := [392.0, 440.0, 330.0, 523.25]
	var root: float = roots[station]
	var intervals := [1.0, 1.25, 1.5]
	for n in range(count):
		var t := float(n) / float(rate)
		var note: int = mini(int(t / 0.22), 2)
		var within: float = fmod(t, 0.22)
		var envelope: float = minf(1.0, within / 0.018) * minf(1.0, (0.22 - within) / 0.070)
		var hz: float = root * float(intervals[note])
		var sample: float = sin(TAU * hz * t) * 0.70 + sin(TAU * hz * 2.0 * t) * 0.12
		bytes.encode_s16(n * 2, int(clampf(sample * envelope * 14500.0, -32000.0, 32000.0)))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = rate
	result.stereo = false
	result.data = bytes
	return result

func apply_tuning(immediate: bool = false) -> void:
	if not is_on:
		_end_voice()
		active_station = -1
		target_reception = 0.0
		reception = 0.0
		music_player.stop()
		static_player.stop()
		jingle_player.stop()
		broadcast_remaining = 0.0
		broadcast_text = ""
		return
	var nearest := -1
	var distance := 999.0
	for i in range(STATIONS.size()):
		var diff: float = absf(frequency - float(STATIONS[i]["freq"]))
		if diff < distance:
			distance = diff
			nearest = i
	var next_station: int = nearest if distance <= MAX_DETUNE else -1
	target_reception = pow(clampf(1.0 - distance / MAX_DETUNE, 0.0, 1.0), 1.4)
	if immediate:
		reception = target_reception
	if next_station != active_station or (next_station >= 0 and music_player.stream == null):
		_end_voice()
		active_station = next_station
		music_player.stop()
		jingle_player.stop()
		broadcast_text = ""
		broadcast_remaining = 0.0
		pending_speech = -1.0
		break_timer = 2.2
		if next_station >= 0:
			music_player.stream = music_streams[next_station]
			if music_player.stream != null:
				music_player.play()
		else:
			music_player.stream = null
	if static_player.stream != null and not static_player.playing:
		static_player.play()
	_update_mix()

func _end_voice() -> void:
	if voice_active and voice_id != "":
		DisplayServer.tts_stop()
	voice_active = false
	voice_elapsed = 0.0
	voice_timeout = 0.0
	pending_speech = -1.0

func _update_mix() -> void:
	if not is_on:
		return
	var strength := pow(clampf(reception, 0.0, 1.0), 1.35)
	var duck := 0.27 if voice_active else 0.94
	music_player.volume_db = linear_to_db(maxf(0.0001, volume * strength * duck))
	static_player.volume_db = linear_to_db(maxf(0.0001, volume * (0.012 + (1.0 - reception) * 0.27)))
	jingle_player.volume_db = linear_to_db(maxf(0.0001, volume * 0.45 * strength))

func _process(delta: float) -> void:
	if not is_on:
		return
	var smoothing: float = 1.0 - exp(-delta * 7.0)
	reception = lerpf(reception, target_reception, smoothing)
	if absf(reception - target_reception) < 0.002:
		reception = target_reception
	if broadcast_remaining > 0.0:
		broadcast_remaining = maxf(0.0, broadcast_remaining - delta)
	if pending_speech >= 0.0:
		pending_speech -= delta
		if pending_speech < 0.0:
			_start_speech()
	if voice_active:
		voice_elapsed += delta
		if voice_elapsed > voice_timeout or (voice_elapsed > 1.0 and not DisplayServer.tts_is_speaking()):
			voice_active = false
	if active_station >= 0 and reception > 0.50:
		break_timer -= delta
		if break_timer <= 0.0:
			_next_broadcast()
	elif active_station < 0:
		break_timer = maxf(break_timer, 2.0)
	_update_mix()
	_health_check += delta
	if _health_check >= 0.75:
		_health_check = 0.0
		if active_station >= 0 and music_player.stream != null and not music_player.playing:
			music_player.play()
		if static_player.stream != null and not static_player.playing:
			static_player.play()

func _next_broadcast() -> void:
	var category := "host"
	if broadcast_count == 0:
		category = "intro"
	elif broadcast_count % 3 == 0:
		category = "weather"
	_queue_broadcast(category)

func request_broadcast() -> void:
	# Manual listener button so spoken radio can be tested without waiting.
	if not is_on or active_station < 0:
		return
	_queue_broadcast("weather" if broadcast_count % 2 == 0 else "host")

func _queue_broadcast(category: String) -> void:
	if active_station < 0:
		return
	_end_voice()
	var time_minutes := 1110.0
	if state != null:
		time_minutes = float(state.time_minutes)
	var item: Dictionary = Programs.get_segment(active_station, category, broadcast_count, time_minutes)
	broadcast_kind = String(item["kind"])
	broadcast_text = String(item["text"])
	broadcast_count += 1
	broadcast_remaining = 14.0
	break_timer = _rng.randf_range(42.0, 72.0)
	jingle_player.stop()
	jingle_player.stream = jingles[active_station]
	if jingle_player.stream != null:
		jingle_player.play()
	pending_speech = 0.75

func _start_speech() -> void:
	if active_station < 0 or not is_on or voice_id == "":
		return
	var tts_volume: int = clampi(roundi(volume * 84.0), 0, 100)
	if tts_volume < 1:
		return
	voice_active = true
	voice_elapsed = 0.0
	voice_timeout = clampf(float(broadcast_text.length()) * 0.085, 5.0, 17.0)
	var pitch: float = [0.95, 0.90, 0.83, 1.08][active_station]
	DisplayServer.tts_speak(broadcast_text, voice_id, tts_volume, pitch, 0.95, broadcast_count, true)

func station_description() -> String:
	if not is_on:
		return "Приёмник выключен."
	if active_station < 0:
		return "Ш-ш-ш... Между станциями. Крути ручку."
	if music_player.stream == null:
		return "Нет записи: проверь файлы audio/*.wav"
	var station: Dictionary = STATIONS[active_station]
	return "%s • %s • СИГНАЛ %d%%" % [station["name"], station["genre"], int(reception * 100.0)]

func broadcast_description() -> String:
	if broadcast_remaining <= 0.0 or broadcast_text == "":
		return ""
	return "%s: %s" % [broadcast_kind, broadcast_text]

func has_russian_voice() -> bool:
	return voice_id != ""

func _exit_tree() -> void:
	_end_voice()
