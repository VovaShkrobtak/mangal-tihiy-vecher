extends Node2D
## Mangal: Tihiy Vecher — Godot 4.x; keyboard, mouse and touchscreen.

const SAVE_PATH := "user://mangal_evening.cfg"
const FOODS := {
	"Свинина": {"target": 22.0, "color": "#d08b86", "veg": false},
	"Говядина": {"target": 27.0, "color": "#ae5a5a", "veg": false},
	"Курица": {"target": 20.0, "color": "#efd4a4", "veg": false},
	"Рыба": {"target": 15.0, "color": "#b4c2bb", "veg": false},
	"Колбаски": {"target": 16.0, "color": "#bf7463", "veg": false},
	"Грибы": {"target": 11.0, "color": "#d7c49b", "veg": true},
	"Овощи": {"target": 10.0, "color": "#d9a45e", "veg": true}
}
const FOOD_ORDER := ["Свинина", "Говядина", "Курица", "Рыба", "Колбаски", "Грибы", "Овощи"]
const STATIONS := [
	{"freq": 88.4, "name": "Лесное FM", "file": "station_forest.wav", "genre": "уютная гитара"},
	{"freq": 93.7, "name": "Дворовая волна", "file": "station_yard.wav", "genre": "ретро-мелодии"},
	{"freq": 100.2, "name": "Полночь", "file": "station_night.wav", "genre": "ночной эмбиент"},
	{"freq": 106.8, "name": "Искра", "file": "station_dance.wav", "genre": "электронная музыка"}
]

var coals := 74.0
var fan_boost := 0.0
var current_food := ""
var food_color := "#cf8580"
var food_is_vegetable := false
var current_target := 20.0
var side_a := 0.0
var side_b := 0.0
var flipped := false
var servings := 0
var spoiled := 0
var comfort := 52.0
var time_minutes := 18.0 * 60.0 + 15.0
var cigarette_left := 0.0
var radio_on := true
var frequency := 93.7
var volume := 0.65
var active_station := -1
var reception := 0.0
var tea_count := 0
var toast_timer := 0.0
var last_toast := "Нажми на мангал или выбери блюдо. Вечер только начинается."
var selected_tab := 0
var ui_tick := 0.0
var save_delay := -1.0

var hud_label: Label
var time_label: Label
var hint_label: Label
var coal_label: Label
var food_label: Label
var progress_bar: ProgressBar
var status_label: Label
var radio_label: Label
var radio_freq_label: Label
var rest_label: Label
var radio_slider: HSlider
var volume_slider: HSlider
var radio_toggle: Button
var food_picker: OptionButton
var panel_holder: Control
var panels: Array[Control] = []
var tabs: Array[Button] = []
var dark_layer: ColorRect
var music_player: AudioStreamPlayer
var noise_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#162031"))
	_load_save()
	var picture := Sprite2D.new()
	picture.name = "PixelArtBackground"
	picture.texture = load("res://assets/backyard.png")
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.centered = false
	add_child(picture)
	var world := Node2D.new()
	world.set_script(load("res://scripts/world.gd"))
	world.set("game", self)
	world.name = "AnimatedWorld"
	add_child(world)
	_create_audio()
	_create_interface()
	_refresh_radio()
	_update_labels()
	_hint(last_toast, 6.0)

func _process(delta: float) -> void:
	time_minutes = fmod(time_minutes + delta * 1.65, 1440.0)
	coals = maxf(0.0, coals - delta * (0.10 + (0.08 if current_food != "" else 0.0)))
	fan_boost = maxf(0.0, fan_boost - delta * 2.0)
	cigarette_left = maxf(0.0, cigarette_left - delta)
	if current_food != "":
		var rate := clampf((coals + fan_boost) / 74.0, 0.0, 1.75)
		if flipped:
			side_b += delta * rate
		else:
			side_a += delta * rate
	if radio_on and active_station >= 0:
		comfort = minf(100.0, comfort + delta * 0.008)
	toast_timer = maxf(0.0, toast_timer - delta)
	if save_delay >= 0.0:
		save_delay -= delta
		if save_delay < 0.0:
			_save_game()
	ui_tick += delta
	if ui_tick > 0.12:
		ui_tick = 0.0
		_update_labels()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_G:
				_set_tab(0)
			KEY_R:
				_set_tab(1)
			KEY_T:
				_set_tab(2)
			KEY_SPACE:
				_flip_food()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_world(event.position)
	if event is InputEventScreenTouch and event.pressed:
		_click_world(event.position)

func _click_world(p: Vector2) -> void:
	if p.y >= 250.0 or p.y < 35.0:
		return
	if p.x >= 280.0 and p.x <= 430.0 and p.y >= 149.0 and p.y <= 229.0:
		_set_tab(0)
		if current_food != "":
			_flip_food()
		else:
			_hint("Мангал горячий. Выбирай продукт в меню!", 3.0)
	elif p.x >= 495.0 and p.x <= 615.0 and p.y >= 115.0 and p.y <= 218.0:
		_set_tab(1)
	elif p.x >= 117.0 and p.x <= 208.0 and p.y >= 111.0 and p.y <= 215.0:
		_set_tab(2)

func _make_label(parent: Node, txt: String, px: float, py: float, size: int = 12, color: Color = Color("#f0e4cf")) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = Vector2(px, py)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

func _make_button(parent: Node, txt: String, px: float, py: float, w: float, h: float, action: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = Vector2(px, py)
	b.size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color("#fff0dc"))
	_apply_button_style(b, false)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _apply_button_style(b: Button, active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#8f5137" if active else "#34404a")
	normal.border_color = Color("#dcaa6a" if active else "#657078")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ae6842")
	b.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#c17b4d")
	b.add_theme_stylebox_override("pressed", pressed)

func _create_interface() -> void:
	var ui := Control.new()
	ui.name = "Hud"
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)

	dark_layer = ColorRect.new()
	dark_layer.position = Vector2(0, 31)
	dark_layer.size = Vector2(640, 220)
	dark_layer.color = Color(0.02, 0.07, 0.16, 0.05)
	dark_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dark_layer)

	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 31)
	top.color = Color("#16232be8")
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	_make_label(ui, "МАНГАЛ • ТИХИЙ ВЕЧЕР", 12, 6, 15, Color("#ffe1a4"))
	hud_label = _make_label(ui, "", 306, 8, 12, Color("#f3dfc2"))
	time_label = _make_label(ui, "", 565, 8, 12, Color("#f3dfc2"))

	var hints := ColorRect.new()
	hints.position = Vector2(12, 219)
	hints.size = Vector2(616, 28)
	hints.color = Color("#1b2535d8")
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hints)
	hint_label = _make_label(ui, "", 22, 225, 12, Color("#ffe2ac"))

	var bottom := ColorRect.new()
	bottom.position = Vector2(0, 251)
	bottom.size = Vector2(640, 109)
	bottom.color = Color("#1a2933")
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bottom)
	var names := ["МАНГАЛ [G]", "РАДИО [R]", "ОТДЫХ [T]"]
	for i in range(names.size()):
		var tab := _make_button(ui, names[i], 8 + i * 210, 254, 202, 22, _set_tab.bind(i))
		tabs.append(tab)

	panel_holder = Control.new()
	panel_holder.position = Vector2(0, 0)
	panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel_holder)
	for i in range(3):
		var panel := Control.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_holder.add_child(panel)
		panels.append(panel)
	_create_grill_panel(panels[0])
	_create_radio_panel(panels[1])
	_create_rest_panel(panels[2])
	_set_tab(0)

func _create_grill_panel(panel: Control) -> void:
	_make_label(panel, "ПРОДУКТ", 12, 278, 10, Color("#adbac2"))
	food_picker = OptionButton.new()
	food_picker.position = Vector2(12, 292)
	food_picker.size = Vector2(145, 26)
	food_picker.add_theme_font_size_override("font_size", 12)
	for item in FOOD_ORDER:
		food_picker.add_item(item)
	panel.add_child(food_picker)
	_make_button(panel, "НА МАНГАЛ", 164, 292, 116, 26, _start_food)
	_make_button(panel, "ПЕРЕВЕРНУТЬ", 286, 292, 131, 26, _flip_food)
	_make_button(panel, "СНЯТЬ", 423, 292, 92, 26, _take_food)
	_make_button(panel, "+ УГЛИ", 522, 292, 106, 26, _add_coals)
	coal_label = _make_label(panel, "", 12, 326, 12, Color("#ffd29e"))
	food_label = _make_label(panel, "", 228, 326, 12, Color("#f3e3ce"))
	_make_button(panel, "РАЗДУТЬ ОГОНЬ", 505, 323, 123, 27, _fan_fire)
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(228, 348)
	progress_bar.size = Vector2(258, 7)
	progress_bar.show_percentage = false
	progress_bar.max_value = 100.0
	panel.add_child(progress_bar)

func _create_radio_panel(panel: Control) -> void:
	radio_toggle = _make_button(panel, "РАДИО: ВКЛ", 12, 283, 115, 28, _toggle_radio)
	radio_slider = HSlider.new()
	radio_slider.position = Vector2(141, 287)
	radio_slider.size = Vector2(339, 21)
	radio_slider.min_value = 87.5
	radio_slider.max_value = 108.0
	radio_slider.step = 0.1
	radio_slider.value = frequency
	radio_slider.value_changed.connect(_on_frequency)
	panel.add_child(radio_slider)
	radio_freq_label = _make_label(panel, "93.7 MHz", 493, 288, 16, Color("#ffe9af"))
	_make_label(panel, "СТАНЦИИ:", 12, 324, 10, Color("#a3b5b9"))
	for i in range(STATIONS.size()):
		var sta: Dictionary = STATIONS[i]
		_make_button(panel, "%0.1f" % float(sta["freq"]), 88 + i * 80, 320, 74, 28, _tune_preset.bind(i))
	_make_label(panel, "ГРОМКОСТЬ", 420, 328, 10, Color("#a3b5b9"))
	volume_slider = HSlider.new()
	volume_slider.position = Vector2(504, 326)
	volume_slider.size = Vector2(124, 22)
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = volume
	volume_slider.value_changed.connect(_on_volume)
	panel.add_child(volume_slider)
	radio_label = _make_label(panel, "", 12, 345, 10, Color("#dfcba7"))

func _create_rest_panel(panel: Control) -> void:
	_make_button(panel, "ЗАКУРИТЬ", 12, 288, 136, 31, _smoke)
	_make_button(panel, "ЧАЙ ИЗ ТЕРМОСА", 156, 288, 162, 31, _drink_tea)
	_make_button(panel, "ПОДКИНУТЬ ДРОВ", 327, 288, 168, 31, _add_coals)
	rest_label = _make_label(panel, "", 12, 326, 12, Color("#f2d7b1"))
	_make_label(panel, "Здесь нет таймеров и заданий. Просто вечер, мангал и радио.", 12, 344, 11, Color("#a9b5b8"))

func _set_tab(index: int) -> void:
	selected_tab = index
	for i in range(panels.size()):
		panels[i].visible = i == index
		_apply_button_style(tabs[i], i == index)

func _start_food() -> void:
	if current_food != "":
		_hint("Сначала сними предыдущие шампуры.", 3.0)
		return
	if coals < 12.0:
		_hint("Угли остыли — подсыпь свежих.", 4.0)
		return
	current_food = FOOD_ORDER[food_picker.selected]
	var item: Dictionary = FOODS[current_food]
	current_target = float(item["target"])
	food_color = String(item["color"])
	food_is_vegetable = bool(item["veg"])
	side_a = 0.0
	side_b = 0.0
	flipped = false
	_play_effect("sizzle.wav")
	_hint("%s на мангале. Не забудь перевернуть!" % current_food, 5.0)

func _flip_food() -> void:
	if current_food == "":
		_hint("Пока нечего переворачивать.", 2.0)
		return
	flipped = not flipped
	_play_effect("sizzle.wav")
	_hint("Перевернули. Теперь жарится другая сторона.", 2.5)

func _take_food() -> void:
	if current_food == "":
		_hint("Шампуры пустые. Выбери продукт!", 2.5)
		return
	var a: float = side_a / current_target
	var b: float = side_b / current_target
	var dish := current_food
	current_food = ""
	if a >= 1.9 or b >= 1.9:
		spoiled += 1
		comfort = maxf(0.0, comfort - 2.0)
		_hint("Эх, %s подгорели. На следующий раз лучше!" % dish, 5.0)
	elif a >= 0.82 and b >= 0.82:
		servings += 1
		comfort = minf(100.0, comfort + 9.0)
		_play_effect("success.wav")
		_hint("Готово! %s — ароматно и вкусно. Порций: %d" % [dish, servings], 5.0)
	else:
		comfort = maxf(0.0, comfort - 1.0)
		_hint("%s сыроваты. В следующий раз подержи подольше." % dish, 5.0)
	_save_game()

func _add_coals() -> void:
	coals = minf(100.0, coals + 38.0)
	_play_effect("coals.wav")
	_hint("Подсыпали углей. Жар усиливается.", 3.0)

func _fan_fire() -> void:
	if coals <= 0.0:
		_hint("Нечего раздувать — сначала насыпь углей.", 2.8)
		return
	fan_boost = minf(42.0, fan_boost + 22.0)
	coals = maxf(0.0, coals - 3.5)
	_play_effect("coals.wav")
	_hint("Вспыхнули яркие языки пламени!", 3.0)

func _smoke() -> void:
	if cigarette_left > 1.0:
		_hint("Сигарета ещё тлеет. Можно не торопиться.", 3.0)
		return
	cigarette_left = 30.0
	_play_effect("lighter.wav")
	_hint("Щёлкнула зажигалка. Дымок уходит в вечернее небо.", 5.0)

func _drink_tea() -> void:
	tea_count += 1
	comfort = minf(100.0, comfort + 4.0)
	_hint("Горячий чай из термоса. Сразу уютнее.", 4.0)
	_save_game()

func _toggle_radio() -> void:
	radio_on = not radio_on
	_refresh_radio()
	_hint("Приёмник включён." if radio_on else "Радио выключено. Слышно потрескивание углей.", 3.0)
	_save_game()

func _on_frequency(value: float) -> void:
	frequency = snappedf(value, 0.1)
	_refresh_radio()
	_schedule_save()

func _on_volume(value: float) -> void:
	volume = value
	_refresh_radio()
	_schedule_save()

func _tune_preset(index: int) -> void:
	radio_slider.value = float(STATIONS[index]["freq"])
	_refresh_radio()

func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "RadioMusic"
	add_child(music_player)
	noise_player = AudioStreamPlayer.new()
	noise_player.name = "FrequencyStatic"
	add_child(noise_player)
	var static_stream: AudioStream = load("res://audio/radio_static.wav")
	if static_stream is AudioStreamWAV:
		static_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	noise_player.stream = static_stream
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "Foley"
	add_child(effects_player)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "EveningAmbience"
	add_child(ambient_player)
	var ambience: AudioStream = load("res://audio/night_ambience.wav")
	if ambience is AudioStreamWAV:
		ambience.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient_player.stream = ambience
	ambient_player.volume_db = -27.0
	ambient_player.play()

func _play_effect(name: String) -> void:
	var path := "res://audio/" + name
	if ResourceLoader.exists(path):
		effects_player.stream = load(path)
		effects_player.volume_db = -9.0
		effects_player.play()

func _refresh_radio() -> void:
	if radio_toggle != null:
		radio_toggle.text = "РАДИО: ВКЛ" if radio_on else "РАДИО: ВЫКЛ"
	if radio_freq_label != null:
		radio_freq_label.text = "%0.1f MHz" % frequency
	if not radio_on:
		active_station = -1
		reception = 0.0
		music_player.stop()
		noise_player.stop()
		return
	var nearest := -1
	var best := 100.0
	for i in range(STATIONS.size()):
		var diff: float = absf(frequency - float(STATIONS[i]["freq"]))
		if diff < best:
			best = diff
			nearest = i
	var new_station := nearest if best <= 0.34 else -1
	reception = clampf(1.0 - best / 0.34, 0.0, 1.0)
	if new_station != active_station:
		active_station = new_station
		music_player.stop()
		if active_station >= 0:
			var file := "res://audio/" + String(STATIONS[active_station]["file"])
			var stream: AudioStream = load(file)
			if stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			music_player.stream = stream
			music_player.play()
	if not noise_player.playing:
		noise_player.play()
	music_player.volume_db = linear_to_db(maxf(0.0001, volume * reception * 0.63))
	noise_player.volume_db = linear_to_db(maxf(0.0001, volume * (0.035 + (1.0 - reception) * 0.20)))

func _update_labels() -> void:
	var hour := int(time_minutes / 60.0)
	var minute := int(time_minutes) % 60
	time_label.text = "%02d:%02d" % [hour, minute]
	hud_label.text = "УЮТ %d%%    ПОРЦИЙ %d" % [int(comfort), servings]
	var dark := 0.05
	if hour >= 20 or hour < 5:
		dark = 0.30 if hour >= 22 or hour < 4 else 0.19
	dark_layer.color = Color(0.015, 0.035, 0.11, dark)
	coal_label.text = "ЖАР: %d%%  %s" % [int(coals), "▰▰▰" if coals > 50 else "▰" if coals > 15 else "○"]
	if current_food == "":
		food_label.text = "ШАМПУРЫ СВОБОДНЫ"
		progress_bar.value = 0.0
	else:
		var a := side_a / current_target
		var b := side_b / current_target
		var state := "ПОДГОРЕЛО" if maxf(a, b) >= 1.9 else "ГОТОВО" if minf(a, b) >= 0.82 else "ЖАРИТСЯ"
		food_label.text = "%s • %s • А %d%% / Б %d%%" % [current_food.to_upper(), state, int(a * 100.0), int(b * 100.0)]
		progress_bar.value = clampf(minf(a, b) * 100.0, 0.0, 100.0)
	if radio_on:
		if active_station >= 0:
			var station: Dictionary = STATIONS[active_station]
			radio_label.text = "В ЭФИРЕ: %s — %s | сигнал %d%%" % [station["name"], station["genre"], int(reception * 100.0)]
		else:
			radio_label.text = "Ш-ш-ш... Между станциями только помехи."
	else:
		radio_label.text = "Приёмник выключен."
	rest_label.text = "УЮТ %d%%  |  ЧАЯ: %d  |  СИГАРЕТА: %s  |  ИСПОРЧЕНО: %d" % [int(comfort), tea_count, "%d c" % int(cigarette_left) if cigarette_left > 0.0 else "нет", spoiled]
	if toast_timer <= 0.0:
		hint_label.text = "ЛКМ/касание: мангал — перевернуть, радио — настройки, персонаж — отдых."

func _hint(message: String, seconds: float = 3.0) -> void:
	last_toast = message
	toast_timer = seconds
	if hint_label != null:
		hint_label.text = message

func _schedule_save() -> void:
	save_delay = 0.75

func _save_game() -> void:
	var save := ConfigFile.new()
	save.set_value("game", "servings", servings)
	save.set_value("game", "spoiled", spoiled)
	save.set_value("game", "tea", tea_count)
	save.set_value("game", "comfort", comfort)
	save.set_value("radio", "enabled", radio_on)
	save.set_value("radio", "frequency", frequency)
	save.set_value("radio", "volume", volume)
	save.save(SAVE_PATH)

func _load_save() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) != OK:
		return
	servings = int(save.get_value("game", "servings", 0))
	spoiled = int(save.get_value("game", "spoiled", 0))
	tea_count = int(save.get_value("game", "tea", 0))
	comfort = clampf(float(save.get_value("game", "comfort", 52.0)), 0.0, 100.0)
	radio_on = bool(save.get_value("radio", "enabled", true))
	frequency = clampf(float(save.get_value("radio", "frequency", 93.7)), 87.5, 108.0)
	volume = clampf(float(save.get_value("radio", "volume", 0.65)), 0.0, 1.0)

func _exit_tree() -> void:
	_save_game()
