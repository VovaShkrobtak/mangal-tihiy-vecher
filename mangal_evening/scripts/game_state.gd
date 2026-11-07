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
var kettle_brewing := 0.0
var kettle_portions := 0
var cup_filled := false
var cigarettes_in_pack := 12
var ashtray_ash := 0
var plates_clean := 4
var plated_food := ""
var unplated_portions := 0
var eaten_portions := 0
var sauce_selected := "Аджика"
var plated_sauce := ""
const SAUCES := ["Аджика", "Кетчуп", "Горчица"]
var radio_on := true
var frequency := 93.7
var volume := 0.75
var ambience_volume := 0.80
var save_delay := -1.0

func _process(delta: float) -> void:
	time_minutes = fmod(time_minutes + delta * 1.65, 1440.0)
	coals = maxf(0.0, coals - delta * (0.10 + (0.08 if current_food != "" else 0.0)))
	fan_boost = maxf(0.0, fan_boost - delta * 2.0)
	kettle_brewing = maxf(0.0, kettle_brewing - delta)
	if kettle_brewing > 0.0 and kettle_brewing <= delta:
		kettle_portions = 3
		notify("Чай настоялся. Хватит на три кружки.")
	var was_lit := cigarette_left > 0.0
	cigarette_left = maxf(0.0, cigarette_left - delta)
	if was_lit and cigarette_left <= 0.0:
		ashtray_ash += 1
		notify("Сигарета догорела. Окурок в пепельнице.")
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

func _smoothstep(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func night_factor() -> float:
	# 18:00 sunset; full night by 22:00; dawn between 04:30 and 06:30.
	var t: float = time_minutes
	if t >= 1080.0 and t < 1320.0:
		return _smoothstep((t - 1080.0) / 240.0)
	if t >= 1320.0 or t < 270.0:
		return 1.0
	if t >= 270.0 and t < 390.0:
		return 1.0 - _smoothstep((t - 270.0) / 120.0)
	return 0.0

func glow_factor() -> float:
	return clampf((coals + fan_boost * 0.7) / 92.0, 0.0, 1.0)

func time_phase_label() -> String:
	var night := night_factor()
	if night >= 0.80:
		return "НОЧЬ"
	if night >= 0.35:
		return "СУМЕРКИ"
	return "ВЕЧЕР"

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
		unplated_portions += 1
		comfort = minf(100.0, comfort + 5.0)
		notify("Готово! %s — можно положить на тарелку. Порций: %d" % [dish, servings], "success.wav")
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
		notify("Сигарета уже тлеет. Не торопись.")
		return
	if cigarettes_in_pack <= 0:
		notify("Пачка пуста. Больше сигарет нет.")
		return
	cigarettes_in_pack -= 1
	cigarette_left = 46.0
	notify("Щёлкнула зажигалка, над столом потянулся дымок.", "lighter.wav")
	schedule_save()

func extinguish_cigarette() -> void:
	if cigarette_left <= 0.0:
		notify("Пепельница стоит на столе. Тушить пока нечего.")
		return
	cigarette_left = 0.0
	ashtray_ash += 1
	notify("Потушили сигарету в пепельнице.")
	schedule_save()

func empty_ashtray() -> void:
	if cigarette_left > 0.0:
		notify("Сначала потуши сигарету.")
		return
	if ashtray_ash <= 0:
		notify("Пепельница и так чистая.")
		return
	ashtray_ash = 0
	notify("Вытряхнули окурки. На столе опять порядок.")
	schedule_save()

func brew_tea() -> void:
	if kettle_brewing > 0.0:
		notify("Чайник уже настаивается. Ещё %d секунд." % int(ceil(kettle_brewing)))
		return
	if kettle_portions > 0:
		notify("В чайнике ещё есть чай. Сначала разлей его.")
		return
	kettle_brewing = 12.0
	notify("Залили кипяток в чайник. Заварка набирает цвет.")
	schedule_save()

func pour_tea() -> void:
	if cup_filled:
		notify("Кружка уже полная. Сначала выпей чай.")
		return
	if kettle_brewing > 0.0:
		notify("Подожди, пока чай настоится.")
		return
	if kettle_portions <= 0:
		notify("Чайник пуст. Сперва завари чай.")
		return
	kettle_portions -= 1
	cup_filled = true
	notify("Горячий чай разлился по кружке.")
	schedule_save()

func drink_tea() -> void:
	if not cup_filled:
		notify("Кружка пустая. Налей чаю из чайника.")
		return
	cup_filled = false
	tea_count += 1
	comfort = minf(100.0, comfort + 4.0)
	notify("Глоток горячего чая. Вечер сразу уютнее.")
	schedule_save()

func put_on_plate() -> void:
	if plated_food != "":
		notify("На тарелке уже есть шашлык. Сначала поешь.")
		return
	if unplated_portions <= 0:
		notify("Нечего накладывать. Сначала приготовь блюдо.")
		return
	if plates_clean <= 0:
		notify("Чистых тарелок не осталось.")
		return
	plates_clean -= 1
	unplated_portions -= 1
	plated_food = "Шашлык"
	plated_sauce = ""
	notify("Выложили готовое мясо на тарелку.")
	schedule_save()

func choose_sauce(index: int) -> void:
	if index < 0 or index >= SAUCES.size():
		return
	sauce_selected = SAUCES[index]
	if plated_food != "":
		plated_sauce = sauce_selected
		notify("На тарелке теперь %s." % plated_sauce)
	else:
		notify("Выбран соус: %s. Добавь его к блюду на тарелке." % sauce_selected)
	schedule_save()

func eat_plate() -> void:
	if plated_food == "":
		notify("Тарелка пустая. Положи на неё шашлык.")
		return
	plated_food = ""
	plated_sauce = ""
	plates_clean += 1
	eaten_portions += 1
	comfort = minf(100.0, comfort + 5.0)
	notify("Вкусно! Тарелку убрали со стола.", "success.wav")
	schedule_save()

func cup_description() -> String:
	if cup_filled:
		return "КРУЖКА: ЧАЙ"
	if kettle_brewing > 0.0:
		return "ЧАЙНИК: %d С" % int(ceil(kettle_brewing))
	return "ЧАЙНИК: %d ПОРЦ." % kettle_portions

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
	kettle_portions = clampi(int(save.get_value("table", "tea_portions", 0)), 0, 3)
	cup_filled = bool(save.get_value("table", "cup_full", false))
	cigarettes_in_pack = clampi(int(save.get_value("table", "cigarettes", 12)), 0, 12)
	ashtray_ash = maxi(0, int(save.get_value("table", "ash", 0)))
	plates_clean = clampi(int(save.get_value("table", "clean_plates", 4)), 0, 4)
	unplated_portions = maxi(0, int(save.get_value("table", "unplated", 0)))
	eaten_portions = maxi(0, int(save.get_value("table", "eaten", 0)))
	plated_food = String(save.get_value("table", "plated", ""))
	plated_sauce = String(save.get_value("table", "sauce_on_plate", ""))
	sauce_selected = String(save.get_value("table", "selected_sauce", "Аджика"))

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
	save.set_value("table", "tea_portions", kettle_portions)
	save.set_value("table", "cup_full", cup_filled)
	save.set_value("table", "cigarettes", cigarettes_in_pack)
	save.set_value("table", "ash", ashtray_ash)
	save.set_value("table", "clean_plates", plates_clean)
	save.set_value("table", "unplated", unplated_portions)
	save.set_value("table", "eaten", eaten_portions)
	save.set_value("table", "plated", plated_food)
	save.set_value("table", "sauce_on_plate", plated_sauce)
	save.set_value("table", "selected_sauce", sauce_selected)
	var err := save.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save game settings: %s" % error_string(err))

func _exit_tree() -> void:
	save_game()
