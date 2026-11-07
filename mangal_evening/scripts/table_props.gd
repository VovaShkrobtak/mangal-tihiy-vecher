extends Node2D
## Tabletop pixel-art items. Clickable objects are part of the actual scene.
## All objects share one hit map, keeping drawing and touch targets in sync.
var state = null
var time := 0.0

const HIT: Dictionary = {
	"plate": Rect2(38, 179, 47, 37),
	"cup": Rect2(91, 158, 34, 51),
	"cigarettes": Rect2(129, 183, 25, 27),
	"ashtray": Rect2(157, 181, 30, 27),
	"kettle": Rect2(205, 147, 39, 65),
	"sauce": Rect2(247, 174, 27, 38)
}

func hit_test(pos: Vector2) -> String:
	# Higher priority for compact objects, to avoid triggering the character behind.
	for name in ["cup", "kettle", "cigarettes", "ashtray", "plate", "sauce"]:
		if HIT[name].has_point(pos):
			return name
	return ""

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _px(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(Vector2(roundf(x), roundf(y)), Vector2(w, h)), color)

func _draw() -> void:
	if state == null:
		return
	_draw_plate()
	_draw_cup()
	_draw_kettle()
	_draw_cigarettes()
	_draw_ashtray()
	_draw_sauces()

func _draw_plate() -> void:
	_px(43, 198, 38, 6, Color("#3d3431"))
	_px(46, 193, 32, 9, Color("#e0c9a6"))
	_px(50, 194, 23, 5, Color("#f5e4c9"))
	_px(52, 195, 19, 3, Color("#c8a88b"))
	if state.plated_food != "":
		for i in range(4):
			_px(54 + i * 5, 190 + i % 2, 6, 6, Color("#9e4c24"))
			_px(55 + i * 5, 191 + i % 2, 3, 2, Color("#ce7d3d"))
		if state.plated_sauce != "":
			var sauce := Color("#bd4b32")
			if state.plated_sauce == "Горчица":
				sauce = Color("#d5b446")
			_px(68, 195, 5, 3, sauce)

func _draw_cup() -> void:
	_px(97, 180, 19, 17, Color("#24303a"))
	_px(100, 179, 15, 16, Color("#e4d5bd"))
	_px(101, 180, 13, 3, Color("#977a61" if not state.cup_filled else "#8f4e2b"))
	_px(117, 183, 5, 9, Color("#d0c1a6"))
	_px(119, 186, 4, 4, Color("#354047"))
	_px(98, 194, 18, 3, Color("#a99b85"))
	if state.cup_filled:
		for i in range(2):
			var wave: float = sin(time * 1.6 + float(i)) * 1.5
			_px(102 + float(i) * 5.0 + wave, 170.0 - float(i) * 4.0, 2, 5, Color(0.92, 0.89, 0.83, 0.35))

func _draw_kettle() -> void:
	_px(214, 161, 22, 34, Color("#333b41"))
	_px(217, 162, 18, 31, Color("#b5a68b"))
	_px(220, 164, 12, 27, Color("#d7c3a0"))
	_px(219, 157, 14, 5, Color("#776856"))
	_px(224, 153, 5, 5, Color("#d0b38d"))
	_px(207, 168, 8, 5, Color("#c3b28e"))
	_px(210, 171, 8, 3, Color("#d7c6a1"))
	_px(235, 167, 4, 17, Color("#43413d"))
	_px(238, 165, 5, 6, Color("#b5a68b"))
	_px(238, 181, 5, 5, Color("#b5a68b"))
	if state.kettle_brewing > 0.0:
		for i in range(2):
			_px(224 + i * 5 + sin(time * 1.1 + i) * 2, 147 - fmod(time * 6.0 + i * 5.0, 10.0), 2, 4, Color(0.88, 0.86, 0.84, 0.5))

func _draw_cigarettes() -> void:
	_px(131, 193, 24, 10, Color("#4a3025"))
	_px(132, 188, 22, 13, Color("#d6ba9b"))
	_px(132, 188, 22, 4, Color("#a8402e"))
	_px(135, 192, 16, 5, Color("#eee0c0"))
	if state.cigarettes_in_pack > 0:
		_px(137, 185, 2, 10, Color("#fff6e5"))
		_px(141, 185, 2, 10, Color("#fff6e5"))
		_px(145, 185, 2, 10, Color("#fff6e5"))

func _draw_ashtray() -> void:
	_px(159, 195, 27, 7, Color("#2b292c"))
	_px(163, 191, 20, 8, Color("#85807a"))
	_px(166, 193, 14, 4, Color("#454548"))
	if state.ashtray_ash > 0:
		for i in range(mini(state.ashtray_ash, 7)):
			_px(166 + i * 2, 192 + i % 2, 3, 2, Color("#c4bcb0"))
	if state.cigarette_left > 0.0:
		_px(174, 190, 8, 2, Color("#e4e0cf"))
		_px(181, 190, 2, 2, Color("#ef793b"))

func _draw_sauces() -> void:
	var cols := [Color("#b43c28"), Color("#cbb345"), Color("#7b3c29")]
	for i in range(3):
		var x: float = 251.0 + float(i * 7)
		_px(x, 184, 6, 14, Color("#322b2a"))
		_px(x + 1, 186, 4, 11, cols[i])
		_px(x + 1, 181, 4, 4, Color("#d3c49f"))
