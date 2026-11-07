extends Control
## Compact pixel HUD: four exclusive tabs, carefully bounded interactive elements.
## Game rules never live here; this view only displays state and emits requests.
signal request(action_name: String, payload: Variant)

const Data = preload("res://scripts/data.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const PixelSlider = preload("res://scripts/pixel_slider.gd")
const RadioDial = preload("res://scripts/radio_dial.gd")

var state = null
var radio = null
var soundscape = null
var selected_tab := 0
var toast_timer := 0.0
var last_toast := "Добро пожаловать во двор. Выбери предмет или действие."

var hud_label: Label
var time_label: Label
var hint_label: Label
var coal_label: Label
var food_label: Label
var progress_bar: ProgressBar
var radio_label: Label
var radio_freq_label: Label
var rest_label: Label
var table_label: Label
var radio_slider: Control
var volume_slider: Control
var ambience_slider: Control
var radio_dial: Control
var reception_bar: ProgressBar
var radio_toggle: Button
var food_picker: OptionButton
var panels: Array[Control] = []
var tabs: Array[Button] = []
var interactive: Array[Control] = []
var pixel_font: FontFile

func setup(game_state: Node, tuner: Node, ambience: Node) -> void:
	state = game_state
	radio = tuner
	soundscape = ambience
	pixel_font = PixelFont.build()
	_create_interface()
	refresh()
	hint(last_toast, 5.0)

func _process(delta: float) -> void:
	if state == null:
		return
	toast_timer = maxf(0.0, toast_timer - delta)
	if toast_timer <= 0.0 and hint_label != null:
		var speech: String = radio.broadcast_description()
		hint_label.text = ("РАДИО: " + speech) if speech != "" else "КАСАНИЕ: СТОЛ — ПРЕДМЕТЫ, МАНГАЛ — ШАМПУРЫ, РАДИО — ВОЛНА."

func _label(parent: Node, txt: String, x: float, y: float, width: float, font_size: int = 11, color: Color = Color("#f2ddbc")) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = Vector2(x, y)
	l.size = Vector2(width, 18)
	l.clip_text = true
	l.add_theme_font_override("font", pixel_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _style(button: Button, active: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#86513a" if active else "#304149")
	normal.border_color = Color("#f0bb76" if active else "#69777c")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(0)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#a35d40")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#bd7548")
	button.add_theme_stylebox_override("pressed", pressed)
	var focused := normal.duplicate() as StyleBoxFlat
	focused.border_color = Color("#ffe6aa")
	button.add_theme_stylebox_override("focus", focused)

func _button(parent: Node, title: String, x: float, y: float, w: float, h: float, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.position = Vector2(x, y)
	button.size = Vector2(w, h)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color("#fff0d5"))
	button.clip_text = true
	_style(button)
	parent.add_child(button)
	button.pressed.connect(callback)
	interactive.append(button)
	return button

func _pixel_slider(parent: Node, x: float, y: float, w: float, min_value: float, max_value: float, step: float, initial: float, on_change: Callable) -> Control:
	var slider := PixelSlider.new()
	slider.position = Vector2(x, y)
	slider.size = Vector2(w, 19)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.set_value_no_signal(initial)
	slider.value_changed.connect(on_change)
	parent.add_child(slider)
	interactive.append(slider)
	return slider

func _bar(parent: Node, x: float, y: float, w: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = Vector2(x, y)
	bar.size = Vector2(w, 8)
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#16262c")
	bg.set_corner_radius_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#dfa15d")
	fill.set_corner_radius_all(0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _rect(parent: Node, x: float, y: float, w: float, h: float, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _create_interface() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_asset := Theme.new()
	theme_asset.default_font = pixel_font
	theme_asset.default_font_size = 10
	theme = theme_asset
	_rect(self, 0, 0, 640, 30, Color("#18272ee8"))
	_label(self, "МАНГАЛ • ТИХИЙ ВЕЧЕР", 11, 7, 218, 11, Color("#ffe4ac"))
	hud_label = _label(self, "", 238, 8, 320, 10, Color("#f0d8ad"))
	time_label = _label(self, "", 569, 8, 62, 11)
	_rect(self, 7, 212, 626, 29, Color("#17252ce7"))
	hint_label = _label(self, "", 15, 220, 611, 10, Color("#ffe0ab"))
	_rect(self, 0, 243, 640, 117, Color("#172932"))
	var names := ["МАНГАЛ [G]", "РАДИО [R]", "ЧАЙ/ТАБАК [T]", "СТОЛ [P]"]
	for i in range(names.size()):
		var tab := _button(self, names[i], 8 + float(i) * 158.0, 246, 150, 27, set_tab.bind(i))
		tabs.append(tab)
	_rect(self, 7, 276, 626, 80, Color("#22343a"))
	for i in range(names.size()):
		var panel := Control.new()
		panel.name = "Tab" + str(i)
		panel.size = Vector2(640, 360)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)
		panels.append(panel)
	_make_grill(panels[0])
	_make_radio(panels[1])
	_make_rest(panels[2])
	_make_table(panels[3])
	set_tab(0)

func _make_grill(panel: Control) -> void:
	_label(panel, "ПРОДУКТ", 12, 277, 110, 9, Color("#b0c1c6"))
	food_picker = OptionButton.new()
	food_picker.position = Vector2(12, 291)
	food_picker.size = Vector2(139, 27)
	food_picker.clip_text = true
	food_picker.add_theme_font_override("font", pixel_font)
	food_picker.add_theme_font_size_override("font_size", 11)
	food_picker.add_theme_color_override("font_color", Color("#fff0d5"))
	for food in Data.FOOD_ORDER:
		food_picker.add_item(food)
	_style(food_picker)
	panel.add_child(food_picker)
	interactive.append(food_picker)
	_button(panel, "НА МАНГАЛ", 155, 291, 112, 27, _send_food)
	_button(panel, "ПЕРЕВЕРНУТЬ", 271, 291, 118, 27, _send.bind("flip"))
	_button(panel, "СНЯТЬ", 393, 291, 73, 27, _send.bind("take"))
	_button(panel, "+УГЛИ", 470, 291, 73, 27, _send.bind("coals"))
	_button(panel, "РАЗДУТЬ", 547, 291, 81, 27, _send.bind("fan"))
	coal_label = _label(panel, "", 12, 326, 127, 11, Color("#ffce92"))
	food_label = _label(panel, "", 144, 326, 480, 11, Color("#e9d7bd"))
	progress_bar = _bar(panel, 144, 347, 480)

func _make_radio(panel: Control) -> void:
	radio_toggle = _button(panel, "РАДИО ВКЛ", 12, 284, 95, 26, _send.bind("power"))
	radio_dial = RadioDial.new()
	radio_dial.name = "TuningKnob"
	radio_dial.position = Vector2(110, 277)
	radio_dial.size = Vector2(50, 38)
	radio_dial.set_frequency(radio.frequency)
	radio_dial.turned.connect(_frequency_changed)
	panel.add_child(radio_dial)
	interactive.append(radio_dial)
	_label(panel, "ЧАСТОТА", 175, 277, 130, 9, Color("#abbec0"))
	radio_slider = _pixel_slider(panel, 176, 292, 231, 87.5, 108.0, 0.1, radio.frequency, _frequency_changed)
	radio_freq_label = _label(panel, "", 415, 287, 113, 13, Color("#ffe5a8"))
	_label(panel, "СИГНАЛ", 545, 279, 82, 9, Color("#b2c6c7"))
	reception_bar = _bar(panel, 545, 296, 79)
	for i in range(Data.STATIONS.size()):
		var station: Dictionary = Data.STATIONS[i]
		_button(panel, "%0.1f" % float(station["freq"]), 12 + float(i) * 79.0, 317, 75, 26, _preset.bind(i))
	_button(panel, "СЛУШАТЬ ЭФИР", 330, 317, 144, 26, _send.bind("radio_broadcast"))
	_button(panel, "ТЕСТ", 479, 317, 75, 26, _send.bind("radio_test"))
	volume_slider = _pixel_slider(panel, 558, 321, 67, 0.0, 1.0, 0.05, radio.volume, _volume_changed)
	radio_label = _label(panel, "", 12, 347, 615, 10, Color("#e4c99e"))

func _make_rest(panel: Control) -> void:
	_button(panel, "ЗАВАРИТЬ", 12, 285, 99, 28, _send.bind("brew"))
	_button(panel, "НАЛИТЬ", 115, 285, 87, 28, _send.bind("pour"))
	_button(panel, "ВЫПИТЬ", 206, 285, 87, 28, _send.bind("tea"))
	_button(panel, "ЗАКУРИТЬ", 297, 285, 104, 28, _send.bind("smoke"))
	_button(panel, "ПОТУШИТЬ", 405, 285, 104, 28, _send.bind("extinguish"))
	_button(panel, "УБРАТЬ ПЕПЕЛ", 513, 285, 115, 28, _send.bind("empty_ashtray"))
	rest_label = _label(panel, "", 12, 320, 612, 11, Color("#ffe0b2"))
	_label(panel, "ФОНОВЫЕ ЗВУКИ", 12, 341, 170, 9, Color("#a6b9b9"))
	ambience_slider = _pixel_slider(panel, 188, 338, 174, 0.0, 1.0, 0.05, soundscape.ambient_volume, _ambient_changed)
	_label(panel, "СДЕЛАЙ ЧАЙ И ПОСИДИ У ОГНЯ.", 370, 341, 254, 9, Color("#b2bdb9"))

func _make_table(panel: Control) -> void:
	_button(panel, "НА ТАРЕЛКУ", 12, 286, 131, 27, _send.bind("plate"))
	_button(panel, "СЪЕСТЬ", 147, 286, 94, 27, _send.bind("eat"))
	_button(panel, "АДЖИКА", 245, 286, 119, 27, _sauce.bind(0))
	_button(panel, "КЕТЧУП", 368, 286, 119, 27, _sauce.bind(1))
	_button(panel, "ГОРЧИЦА", 491, 286, 137, 27, _sauce.bind(2))
	table_label = _label(panel, "", 12, 321, 612, 11, Color("#ffdeb2"))
	_label(panel, "НАЖМИ НА ПРЕДМЕТЫ НА СТОЛЕ, ЧТОБЫ ВЗЯТЬ ИХ.", 12, 344, 610, 9, Color("#a7b9b9"))

func _send(action: String) -> void:
	request.emit(action, null)

func _send_food() -> void:
	request.emit("start", Data.FOOD_ORDER[food_picker.selected])

func _sauce(index: int) -> void:
	request.emit("sauce", index)

func _preset(index: int) -> void:
	request.emit("preset", index)
	radio_slider.set_value_no_signal(float(Data.STATIONS[index]["freq"]))
	radio_dial.set_frequency(float(Data.STATIONS[index]["freq"]))

func _frequency_changed(mhz: float) -> void:
	radio_slider.set_value_no_signal(mhz)
	radio_dial.set_frequency(mhz)
	request.emit("frequency", mhz)

func _volume_changed(v: float) -> void:
	request.emit("volume", v)

func _ambient_changed(v: float) -> void:
	request.emit("ambient", v)

func set_tab(index: int) -> void:
	if index < 0 or index >= panels.size():
		return
	selected_tab = index
	for i in range(panels.size()):
		panels[i].visible = i == index
		_style(tabs[i], i == index)

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
	hud_label.text = "УЮТ %d%% • %s • ГОТОВО %d" % [int(state.comfort), state.time_phase_label(), state.servings]
	coal_label.text = "ЖАР %d%%" % int(state.coals)
	if state.current_food == "":
		food_label.text = "ШАМПУРЫ СВОБОДНЫ"
		progress_bar.value = 0
	else:
		var a: float = state.side_a / maxf(state.current_target, 0.1)
		var b: float = state.side_b / maxf(state.current_target, 0.1)
		var status := "ГОРИТ" if maxf(a, b) >= 1.9 else "ГОТОВО" if minf(a, b) >= 0.82 else "ЖАРИТСЯ"
		food_label.text = "%s • %s • A %d%% / Б %d%%" % [state.current_food, status, int(a * 100), int(b * 100)]
		progress_bar.value = clampf(minf(a, b) * 100.0, 0.0, 100.0)
	radio_toggle.text = "РАДИО ВКЛ" if radio.is_on else "РАДИО ВЫКЛ"
	radio_freq_label.text = "%0.1f МГЦ" % radio.frequency
	reception_bar.value = radio.reception * 100.0
	var program: String = radio.broadcast_description()
	radio_label.text = program if program != "" else radio.station_description()
	if not is_equal_approx(radio_slider.value, radio.frequency):
		radio_slider.set_value_no_signal(radio.frequency)
	if not is_equal_approx(radio_dial.frequency, radio.frequency):
		radio_dial.set_frequency(radio.frequency)
	if not is_equal_approx(volume_slider.value, radio.volume):
		volume_slider.set_value_no_signal(radio.volume)
	rest_label.text = "%s • СИГАРЕТ %d • ОКУРКОВ %d • ЧАЙ ВЫПИТО %d" % [state.cup_description(), state.cigarettes_in_pack, state.ashtray_ash, state.tea_count]
	var plate_info := "ТАРЕЛКА: ПУСТО" if state.plated_food == "" else "ТАРЕЛКА: %s %s" % [state.plated_food, state.plated_sauce]
	table_label.text = "%s • ГОТОВЫХ ПОРЦИЙ %d • ЧИСТЫХ ТАРЕЛОК %d • СОУС %s" % [plate_info, state.unplated_portions, state.plates_clean, state.sauce_selected]

func layout_errors() -> PackedStringArray:
	# CI regression guard: every clickable region must be in the 640x360 viewport,
	# and interactive elements on the currently visible tab must never overlap.
	var issues := PackedStringArray()
	var current := selected_tab
	for t in range(panels.size()):
		set_tab(t)
		var visible_controls: Array[Control] = []
		for control in interactive:
			if not control.is_visible_in_tree():
				continue
			var rect: Rect2 = control.get_global_rect()
			if rect.position.x < -0.01 or rect.position.y < -0.01 or rect.end.x > 640.01 or rect.end.y > 360.01:
				issues.append("Out of bounds: " + str(control))
			for other in visible_controls:
				if rect.intersects(other.get_global_rect()):
					issues.append("Overlap: %s and %s at tab %d" % [control.name, other.name, t])
			visible_controls.append(control)
	set_tab(current)
	return issues
