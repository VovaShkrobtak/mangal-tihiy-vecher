extends Control
## Only the UI. Emits intent; never edits the world state or plays audio.

signal request(action_name: String, payload: Variant)
const Data = preload("res://scripts/data.gd")

var state = null
var radio = null
var soundscape = null
var selected_tab := 0
var toast_timer := 0.0
var last_toast := "Нажми на мангал или выбери блюдо. Вечер только начинается."

var hud_label: Label
var time_label: Label
var hint_label: Label
var coal_label: Label
var food_label: Label
var progress_bar: ProgressBar
var radio_label: Label
var radio_freq_label: Label
var rest_label: Label
var radio_slider: HSlider
var volume_slider: HSlider
var ambience_slider: HSlider
var radio_toggle: Button
var food_picker: OptionButton
var panel_holder: Control
var panels: Array[Control] = []
var tabs: Array[Button] = []
var dark_layer: ColorRect

func setup(game_state: Node, tuner: Node, atmosphere: Node) -> void:
	state = game_state
	radio = tuner
	soundscape = atmosphere
	_create_interface()
	refresh()
	hint(last_toast, 6.0)

func _process(delta: float) -> void:
	if state == null:
		return
	toast_timer = maxf(0.0, toast_timer - delta)
	if toast_timer <= 0.0 and hint_label != null:
		hint_label.text = "ЛКМ/касание: мангал — перевернуть, радио — настройки, персонаж — отдых."

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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_layer = ColorRect.new()
	dark_layer.position = Vector2(0, 31)
	dark_layer.size = Vector2(640, 220)
	dark_layer.color = Color(0.02, 0.07, 0.16, 0.05)
	dark_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark_layer)

	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 31)
	top.color = Color("#16232be8")
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_make_label(self, "МАНГАЛ • ТИХИЙ ВЕЧЕР", 12, 6, 15, Color("#ffe1a4"))
	hud_label = _make_label(self, "", 306, 8, 12, Color("#f3dfc2"))
	time_label = _make_label(self, "", 565, 8, 12, Color("#f3dfc2"))

	var hints := ColorRect.new()
	hints.position = Vector2(12, 219)
	hints.size = Vector2(616, 28)
	hints.color = Color("#1b2535d8")
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hints)
	hint_label = _make_label(self, "", 22, 225, 12, Color("#ffe2ac"))

	var bottom := ColorRect.new()
	bottom.position = Vector2(0, 251)
	bottom.size = Vector2(640, 109)
	bottom.color = Color("#1a2933")
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	var names := ["МАНГАЛ [G]", "РАДИО [R]", "ОТДЫХ [T]"]
	for i in range(names.size()):
		var tab := _make_button(self, names[i], 8 + i * 210, 254, 202, 22, set_tab.bind(i))
		tabs.append(tab)

	panel_holder = Control.new()
	panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_holder)
	for i in range(3):
		var panel := Control.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_holder.add_child(panel)
		panels.append(panel)
	_create_grill_panel(panels[0])
	_create_radio_panel(panels[1])
	_create_rest_panel(panels[2])
	set_tab(0)

func _create_grill_panel(panel: Control) -> void:
	_make_label(panel, "ПРОДУКТ", 12, 278, 10, Color("#adbac2"))
	food_picker = OptionButton.new()
	food_picker.position = Vector2(12, 292)
	food_picker.size = Vector2(145, 26)
	food_picker.add_theme_font_size_override("font_size", 12)
	for item in Data.FOOD_ORDER:
		food_picker.add_item(item)
	panel.add_child(food_picker)
	_make_button(panel, "НА МАНГАЛ", 164, 292, 116, 26, _send_food)
	_make_button(panel, "ПЕРЕВЕРНУТЬ", 286, 292, 131, 26, _send.bind("flip"))
	_make_button(panel, "СНЯТЬ", 423, 292, 92, 26, _send.bind("take"))
	_make_button(panel, "+ УГЛИ", 522, 292, 106, 26, _send.bind("coals"))
	coal_label = _make_label(panel, "", 12, 326, 12, Color("#ffd29e"))
	food_label = _make_label(panel, "", 228, 326, 12, Color("#f3e3ce"))
	_make_button(panel, "РАЗДУТЬ ОГОНЬ", 505, 323, 123, 27, _send.bind("fan"))
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(228, 348)
	progress_bar.size = Vector2(258, 7)
	progress_bar.show_percentage = false
	progress_bar.max_value = 100.0
	panel.add_child(progress_bar)

func _create_radio_panel(panel: Control) -> void:
	radio_toggle = _make_button(panel, "РАДИО: ВКЛ", 12, 283, 115, 28, _send.bind("power"))
	radio_slider = HSlider.new()
	radio_slider.position = Vector2(141, 287)
	radio_slider.size = Vector2(339, 21)
	radio_slider.min_value = 87.5
	radio_slider.max_value = 108.0
	radio_slider.step = 0.1
	radio_slider.value = radio.frequency
	radio_slider.value_changed.connect(_frequency_changed)
	panel.add_child(radio_slider)
	radio_freq_label = _make_label(panel, "", 493, 288, 16, Color("#ffe9af"))
	_make_label(panel, "СТАНЦИИ:", 12, 324, 10, Color("#a3b5b9"))
	for i in range(Data.STATIONS.size()):
		var station: Dictionary = Data.STATIONS[i]
		_make_button(panel, "%0.1f" % float(station["freq"]), 88 + i * 80, 320, 74, 28, _preset.bind(i))
	_make_label(panel, "ГРОМКОСТЬ", 420, 328, 10, Color("#a3b5b9"))
	volume_slider = HSlider.new()
	volume_slider.position = Vector2(504, 326)
	volume_slider.size = Vector2(124, 22)
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = radio.volume
	volume_slider.value_changed.connect(_volume_changed)
	panel.add_child(volume_slider)
	radio_label = _make_label(panel, "", 12, 345, 10, Color("#dfcba7"))
	_make_button(panel, "ТЕСТ", 561, 346, 67, 13, _send.bind("radio_test"))

func _create_rest_panel(panel: Control) -> void:
	_make_button(panel, "ЗАКУРИТЬ", 12, 288, 136, 31, _send.bind("smoke"))
	_make_button(panel, "ЧАЙ ИЗ ТЕРМОСА", 156, 288, 162, 31, _send.bind("tea"))
	_make_button(panel, "ПОДКИНУТЬ ДРОВ", 327, 288, 168, 31, _send.bind("coals"))
	rest_label = _make_label(panel, "", 12, 326, 11, Color("#f2d7b1"))
	_make_label(panel, "ФОН", 420, 345, 10, Color("#a9b5b8"))
	ambience_slider = HSlider.new()
	ambience_slider.position = Vector2(455, 338)
	ambience_slider.size = Vector2(169, 18)
	ambience_slider.min_value = 0.0
	ambience_slider.max_value = 1.0
	ambience_slider.step = 0.05
	ambience_slider.value = soundscape.ambient_volume
	ambience_slider.value_changed.connect(_ambient_changed)
	panel.add_child(ambience_slider)
	_make_label(panel, "Здесь нет заданий. Просто вечер, мангал и радио.", 12, 343, 10, Color("#a9b5b8"))

func _send(action_name: String) -> void:
	request.emit(action_name, null)

func _send_food() -> void:
	request.emit("start", Data.FOOD_ORDER[food_picker.selected])

func _preset(index: int) -> void:
	request.emit("preset", index)
	# Synchronize thumb without emitting a duplicate tuning request.
	radio_slider.set_value_no_signal(float(Data.STATIONS[index]["freq"]))

func _frequency_changed(mhz: float) -> void:
	request.emit("frequency", mhz)

func _volume_changed(value: float) -> void:
	request.emit("volume", value)

func _ambient_changed(value: float) -> void:
	request.emit("ambient", value)

func set_tab(index: int) -> void:
	selected_tab = index
	for i in range(panels.size()):
		panels[i].visible = i == index
		_apply_button_style(tabs[i], i == index)

func hint(message: String, seconds: float = 3.0) -> void:
	last_toast = message
	toast_timer = seconds
	if hint_label != null:
		hint_label.text = message

func refresh() -> void:
	if state == null:
		return
	var hour: int = int(state.time_minutes / 60.0)
	var minute: int = int(state.time_minutes) % 60
	time_label.text = "%02d:%02d" % [hour, minute]
	hud_label.text = "УЮТ %d%%    ПОРЦИЙ %d" % [int(state.comfort), state.servings]
	var darkness := 0.05
	if hour >= 20 or hour < 5:
		darkness = 0.30 if hour >= 22 or hour < 4 else 0.19
	dark_layer.color = Color(0.015, 0.035, 0.11, darkness)
	coal_label.text = "ЖАР: %d%%  %s" % [int(state.coals), "▰▰▰" if state.coals > 50 else "▰" if state.coals > 15 else "○"]
	if state.current_food == "":
		food_label.text = "ШАМПУРЫ СВОБОДНЫ"
		progress_bar.value = 0.0
	else:
		var a: float = state.side_a / state.current_target
		var b: float = state.side_b / state.current_target
		var result := "ПОДГОРЕЛО" if maxf(a, b) >= 1.9 else "ГОТОВО" if minf(a, b) >= 0.82 else "ЖАРИТСЯ"
		food_label.text = "%s • %s • А %d%% / Б %d%%" % [state.current_food.to_upper(), result, int(a * 100.0), int(b * 100.0)]
		progress_bar.value = clampf(minf(a, b) * 100.0, 0.0, 100.0)
	radio_toggle.text = "РАДИО: ВКЛ" if radio.is_on else "РАДИО: ВЫКЛ"
	radio_freq_label.text = "%0.1f MHz" % radio.frequency
	radio_label.text = radio.station_description()
	rest_label.text = "УЮТ %d%%  |  ЧАЯ: %d  |  СИГАРЕТА: %s  |  ИСПОРЧЕНО: %d" % [int(state.comfort), state.tea_count, "%d c" % int(state.cigarette_left) if state.cigarette_left > 0.0 else "нет", state.spoiled]
	# The test restores its own volume; update sliders only when changed from a button.
	if not is_equal_approx(volume_slider.value, radio.volume):
		volume_slider.set_value_no_signal(radio.volume)
	if not is_equal_approx(radio_slider.value, radio.frequency):
		radio_slider.set_value_no_signal(radio.frequency)
