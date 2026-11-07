extends SceneTree
## Headless regression test for the modular scene and its continuous audio.

func _initialize() -> void:
	call_deferred("run_test")

func fail(reason: String) -> void:
	push_error(reason)
	quit(1)

func run_test() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		fail("Could not load main scene")
		return
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	var state: Node = main.get_node("GameState")
	var radio: Node = main.get_node("Radio")
	var soundscape: Node = main.get_node("Soundscape")
	var hud: Control = main.get_node("HUD")
	var atmosphere: Node2D = main.get_node("Atmosphere")
	if atmosphere.get("state") != state:
		fail("Atmosphere is not linked to GameState")
		return
	var previous_time: float = state.get("time_minutes")
	state.set("time_minutes", 1080.0)
	if float(state.call("night_factor")) > 0.01:
		fail("At sunset the night factor must begin near zero")
		return
	state.set("time_minutes", 1380.0)
	if float(state.call("night_factor")) < 0.99:
		fail("At 23:00 the night factor should be one")
		return
	state.set("time_minutes", previous_time)
	if soundscape.get("detail_player") == null:
		fail("Living ambient audio player is missing")
		return
	if hud.get("food_picker") == null:
		fail("Grill interface is missing")
		return
	state.call("start_food", "Свинина")
	if String(state.get("current_food")) != "Свинина":
		fail("Grill did not accept a food choice")
		return
	state.call("flip_food")
	state.call("take_food")
	state.call("smoke")
	if float(state.get("cigarette_left")) < 1.0:
		fail("Cigarette mechanic failed")
		return
	# A default scene should play the evening ambience continuously.
	var ambient: AudioStreamPlayer = soundscape.get("ambient_player")
	if ambient.stream == null or not ambient.playing or ambient.volume_db < -18.0:
		fail("Evening ambience is missing, stopped or inaudibly quiet")
		return
	# Test button must defeat an old saved radio mute/off and switch to known preset.
	radio.call("set_power", false)
	radio.call("set_volume", 0.0)
	main.call("_on_action", "radio_test", null)
	await process_frame
	var music: AudioStreamPlayer = radio.get("music_player")
	if not bool(radio.get("is_on")) or int(radio.get("active_station")) != 1:
		fail("Radio test did not tune the expected 93.7 MHz station")
		return
	if music.stream == null or not music.playing or music.volume_db < -8.0:
		fail("Radio music is missing, stopped or inaudibly quiet")
		return
	var wav := music.stream as AudioStreamWAV
	if wav == null or wav.loop_mode != AudioStreamWAV.LOOP_FORWARD or wav.loop_end <= 0:
		fail("Radio WAV is not configured for seamless looping")
		return
	print("PASS: modular scene, grill, cigarette, audible ambience, radio playback and looping")
	quit(0)
