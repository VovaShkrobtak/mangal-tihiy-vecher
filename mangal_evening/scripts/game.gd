extends Node2D
## Composition root: connects game rules, HUD, radio and soundscape.

@onready var state = $GameState
@onready var radio = $Radio
@onready var soundscape = $Soundscape
@onready var world = $AnimatedWorld
@onready var atmosphere = $Atmosphere
@onready var hud = $HUD
var ui_tick := 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#162031"))
	state.load_save()
	radio.configure(state.radio_on, state.frequency, state.volume)
	soundscape.state = state
	soundscape.configure(state.ambience_volume)
	world.state = state
	world.radio = radio
	atmosphere.state = state
	state.message.connect(_on_message)
	hud.request.connect(_on_action)
	hud.setup(state, radio, soundscape)

func _process(delta: float) -> void:
	if radio.is_on and radio.active_station >= 0:
		state.comfort = minf(100.0, state.comfort + delta * 0.008)
	ui_tick += delta
	if ui_tick >= 0.12:
		ui_tick = 0.0
		hud.refresh()

func _on_message(text: String, effect: String) -> void:
	hud.hint(text, 4.0)
	if effect != "":
		soundscape.play_effect(effect)

func _on_action(action_name: String, payload: Variant) -> void:
	match action_name:
		"start": state.start_food(String(payload))
		"flip": state.flip_food()
		"take": state.take_food()
		"coals": state.add_coals()
		"fan": state.fan_fire()
		"smoke": state.smoke()
		"tea": state.drink_tea()
		"power":
			radio.set_power(not radio.is_on)
			state.radio_on = radio.is_on
			state.notify("Приёмник включён." if radio.is_on else "Радио выключено. Слышно потрескивание углей.")
			state.schedule_save()
		"frequency":
			radio.set_frequency(float(payload))
			state.frequency = radio.frequency
			state.schedule_save()
		"volume":
			radio.set_volume(float(payload))
			state.volume = radio.volume
			state.schedule_save()
		"preset":
			radio.tune_preset(int(payload))
			state.frequency = radio.frequency
			state.schedule_save()
		"radio_test":
			radio.test_station()
			state.radio_on = radio.is_on
			state.frequency = radio.frequency
			state.volume = radio.volume
			state.notify("Проверка: 93.7 МГц, громкость не ниже 75%. Должна играть мелодия.")
			state.schedule_save()
		"ambient":
			soundscape.set_ambient_volume(float(payload))
			state.ambience_volume = soundscape.ambient_volume
			state.schedule_save()
	hud.refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G: hud.set_tab(0)
			KEY_R: hud.set_tab(1)
			KEY_T: hud.set_tab(2)
			KEY_SPACE: state.flip_food()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_world(event.position)
	if event is InputEventScreenTouch and event.pressed:
		_click_world(event.position)

func _click_world(p: Vector2) -> void:
	if p.y >= 250.0 or p.y < 35.0:
		return
	if p.x >= 280.0 and p.x <= 430.0 and p.y >= 149.0 and p.y <= 229.0:
		hud.set_tab(0)
		if state.current_food != "":
			state.flip_food()
		else:
			hud.hint("Мангал горячий. Выбирай продукт в меню!")
	elif p.x >= 495.0 and p.x <= 615.0 and p.y >= 115.0 and p.y <= 218.0:
		hud.set_tab(1)
	elif p.x >= 117.0 and p.x <= 208.0 and p.y >= 111.0 and p.y <= 215.0:
		hud.set_tab(2)
