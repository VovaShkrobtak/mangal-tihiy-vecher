extends Node
## Game rules and persisted data, independent of rendering and sound playback.

signal message(text: String, effect: String)
const Data = preload("res://scripts/data.gd")
const SAVE_PATH := "user://mangal_evening.cfg"

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
var tea_count := 0
var radio_on := true
var frequency := 93.7
var volume := 0.75
var ambience_volume := 0.80
var save_delay := -1.0

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
	if save_delay >= 0.0:
		save_delay -= delta
		if save_delay < 0.0:
			save_game()

func notify(text: String, effect: String = "") -> void:
	message.emit(text, effect)

func start_food(food: String) -> void:
	if current_food != "":
		notify("Сначала сними предыдущие шампуры.")
		return
	if coals < 12.0:
		notify("Угли остыли — подсыпь свежих.")
		return
	if not Data.FOODS.has(food):
		return
	current_food = food
	var item: Dictionary = Data.FOODS[food]
	current_target = float(item["target"])
	food_color = String(item["color"])
	food_is_vegetable = bool(item["veg"])
	side_a = 0.0
	side_b = 0.0
	flipped = false
	notify("%s на мангале. Не забудь перевернуть!" % food, "sizzle.wav")

func flip_food() -> void:
	if current_food == "":
		notify("Пока нечего переворачивать.")
		return
	flipped = not flipped
	notify("Перевернули. Теперь жарится другая сторона.", "sizzle.wav")

func take_food() -> void:
	if current_food == "":
		notify("Шампуры пустые. Выбери продукт!")
		return
	var a: float = side_a / current_target
	var b: float = side_b / current_target
	var dish := current_food
	current_food = ""
	if a >= 1.9 or b >= 1.9:
		spoiled += 1
		comfort = maxf(0.0, comfort - 2.0)
		notify("Эх, %s подгорели. На следующий раз лучше!" % dish)
	elif a >= 0.82 and b >= 0.82:
		servings += 1
		comfort = minf(100.0, comfort + 9.0)
		notify("Готово! %s — ароматно и вкусно. Порций: %d" % [dish, servings], "success.wav")
	else:
		comfort = maxf(0.0, comfort - 1.0)
		notify("%s сыроваты. В следующий раз подержи подольше." % dish)
	schedule_save()

func add_coals() -> void:
	coals = minf(100.0, coals + 38.0)
	notify("Подсыпали углей. Жар усиливается.", "coals.wav")

func fan_fire() -> void:
	if coals <= 0.0:
		notify("Нечего раздувать — сначала насыпь углей.")
		return
	fan_boost = minf(42.0, fan_boost + 22.0)
	coals = maxf(0.0, coals - 3.5)
	notify("Вспыхнули яркие языки пламени!", "coals.wav")

func smoke() -> void:
	if cigarette_left > 1.0:
		notify("Сигарета ещё тлеет. Можно не торопиться.")
		return
	cigarette_left = 30.0
	notify("Щёлкнула зажигалка. Дымок уходит в вечернее небо.", "lighter.wav")

func drink_tea() -> void:
	tea_count += 1
	comfort = minf(100.0, comfort + 4.0)
	notify("Горячий чай из термоса. Сразу уютнее.")
	schedule_save()

func schedule_save() -> void:
	save_delay = 0.75

func load_save() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) != OK:
		return
	servings = int(save.get_value("game", "servings", 0))
	spoiled = int(save.get_value("game", "spoiled", 0))
	tea_count = int(save.get_value("game", "tea", 0))
	comfort = clampf(float(save.get_value("game", "comfort", 52.0)), 0.0, 100.0)
	radio_on = bool(save.get_value("radio", "enabled", true))
	frequency = clampf(float(save.get_value("radio", "frequency", 93.7)), 87.5, 108.0)
	volume = clampf(float(save.get_value("radio", "volume", 0.75)), 0.0, 1.0)
	ambience_volume = clampf(float(save.get_value("audio", "ambient_volume", 0.80)), 0.0, 1.0)

func save_game() -> void:
	var save := ConfigFile.new()
	save.set_value("game", "servings", servings)
	save.set_value("game", "spoiled", spoiled)
	save.set_value("game", "tea", tea_count)
	save.set_value("game", "comfort", comfort)
	save.set_value("radio", "enabled", radio_on)
	save.set_value("radio", "frequency", frequency)
	save.set_value("radio", "volume", volume)
	save.set_value("audio", "ambient_volume", ambience_volume)
	var err := save.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save game settings: %s" % error_string(err))

func _exit_tree() -> void:
	save_game()
