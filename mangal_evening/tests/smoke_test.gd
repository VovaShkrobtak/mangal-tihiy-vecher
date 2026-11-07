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
	var dial: Control = hud.get("radio_dial")
	var strength: ProgressBar = hud.get("reception_bar")
	if dial == null or strength == null:
		fail("Analogue tuning controls are missing")
		return
	if hud.get_node_or_null("TuningKnob") != null:
		fail("Radio dial must live in the radio tab")
		return
	if hud.panels.size() < 2 or hud.panels[1].get_node_or_null("TuningKnob") == null:
		fail("Cannot find tuning knob on radio panel")
		return
	var visual: Node = main.get_node("TableProps")
	if visual.call("hit_test", Vector2(105, 182)) != "cup":
		fail("Cup hitbox is missing")
		return
	var missing_font: Font = hud.get("pixel_font")
	if missing_font == null:
		fail("Pixel Cyrillic font is missing")
		return
	if missing_font.get_glyph_list(0, Vector2i(8, 0)).size() < 70:
		fail("Pixel font has too few glyphs")
		return
	var ui_issues: PackedStringArray = hud.call("layout_errors")
	if not ui_issues.is_empty():
		fail("HUD overlaps or clips: " + ", ".join(ui_issues))
		return
	if hud.get("food_picker") == null:
		fail("Grill interface is missing")
		return
	state.call("brew_tea")
	if float(state.get("kettle_brewing")) <= 0.0:
		fail("Tea did not start brewing")
		return
	state.call("_process", 13.0)
	if int(state.get("kettle_portions")) != 3:
		fail("Kettle did not become ready")
		return
	state.call("pour_tea")
	if not bool(state.get("cup_filled")):
		fail("Cup was not filled")
		return
	state.call("drink_tea")
	if bool(state.get("cup_filled")) or int(state.get("tea_count")) <= 0:
		fail("Drinking tea failed")
		return
	state.call("smoke")
	if int(state.get("cigarettes_in_pack")) >= 12:
		fail("Smoking did not consume a cigarette")
		return
	state.call("extinguish_cigarette")
	if int(state.get("ashtray_ash")) <= 0:
		fail("Ashtray did not receive the cigarette")
		return
	state.call("empty_ashtray")
	if int(state.get("ashtray_ash")) != 0:
		fail("Ashtray could not be emptied")
		return
	state.call("start_food", "Свинина")
	if String(state.get("current_food")) != "Свинина":
		fail("Grill did not accept a food choice")
		return
	state.call("flip_food")
	state.set("side_a", float(state.get("current_target")))
	state.set("side_b", float(state.get("current_target")))
	state.call("take_food")
	if int(state.get("unplated_portions")) < 1:
		fail("Finished food not available to plate")
		return
	state.call("put_on_plate")
	if String(state.get("plated_food")) == "":
		fail("Serving a plate failed")
		return
	var before_sauce: String = state.get("sauce_selected")
	main.call("_click_world", Vector2(260, 193))
	if String(state.get("sauce_selected")) == before_sauce:
		fail("Tapping sauce bottles did not cycle sauce")
		return
	state.call("choose_sauce", 1)
	if String(state.get("plated_sauce")) != "Кетчуп":
		fail("Applying sauce failed")
		return
	state.call("eat_plate")
	if int(state.get("eaten_portions")) < 1:
		fail("Eating from a plate failed")
		return
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
	var radio_bus: int = AudioServer.get_bus_index("VintageRadio")
	if radio_bus < 0 or AudioServer.get_bus_effect_count(radio_bus) < 2:
		fail("Old-style speaker filtering bus is missing")
		return
	radio.call("set_frequency", 95.3)
	if int(radio.get("active_station")) != -1:
		fail("Out-of-band tuning should produce static")
		return
	radio.call("set_frequency", 93.7)
	if int(radio.get("active_station")) != 1:
		fail("Fine tuning cannot reacquire the station")
		return
	radio.call("request_broadcast")
	if String(radio.get("broadcast_text")).is_empty():
		fail("Host/weather broadcast content is missing")
		return
	var jingle: AudioStreamPlayer = radio.get("jingle_player")
	if jingle.stream == null or not jingle.playing:
		fail("Generated station ident is not playing")
		return
	print("PASS: speaker filter, tuning knob, static, radio ident, broadcast, ambience and gameplay")
	quit(0)
