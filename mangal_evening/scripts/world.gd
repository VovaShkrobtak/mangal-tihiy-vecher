extends Node2D
## Pixel-precise animated details painted above the static background.

var state = null
var radio = null
var phase := 0.0
var smoke_particles: Array[Dictionary] = []
var ember_particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for i in range(14):
		ember_particles.append({"x": rng.randf_range(300.0, 414.0), "y": rng.randf_range(180.0, 192.0), "p": rng.randf()})

func _process(delta: float) -> void:
	phase += delta
	if state != null and state.cigarette_left > 0.0 and smoke_particles.size() < 24:
		if rng.randf() < delta * 6.0:
			smoke_particles.append({"x": 167.0, "y": 157.0, "life": 0.0, "max": rng.randf_range(1.8, 3.2), "vx": rng.randf_range(-5.0, 3.0)})
	if state != null and state.coals > 4.0 and smoke_particles.size() < 24:
		if rng.randf() < delta * 3.0:
			smoke_particles.append({"x": rng.randf_range(322.0, 395.0), "y": 180.0, "life": 0.0, "max": rng.randf_range(2.0, 4.0), "vx": rng.randf_range(-5.0, 5.0)})
	for p in smoke_particles:
		p["life"] += delta
		p["x"] += float(p["vx"]) * delta + sin(phase * 1.4 + float(p["life"]) * 6.0) * delta * 1.4
		p["y"] -= delta * 9.0
	for i in range(smoke_particles.size() - 1, -1, -1):
		if float(smoke_particles[i]["life"]) >= float(smoke_particles[i]["max"]):
			smoke_particles.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if state == null:
		return
	_draw_fireflies()
	_draw_coals_and_flames()
	_draw_skewer()
	_draw_cigarette()
	_draw_smoke()

func _pixel_rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), w, h), color)

func _draw_fireflies() -> void:
	for i in range(13):
		var x := 24.0 + fmod(float(i * 97), 592.0)
		var y := 92.0 + fmod(float(i * 47), 128.0)
		var alpha: float = (0.08 + maxf(0.0, sin(phase * 1.3 + float(i * 8))) * 0.55) * (0.45 + state.night_factor() * 0.55)
		_pixel_rect(x + sin(phase * 0.25 + float(i)) * 5.0, y + cos(phase * 0.34 + float(i)) * 4.0, 2, 2, Color(1.0, 0.91, 0.48, alpha))

func _draw_coals_and_flames() -> void:
	var intensity: float = clampf(state.coals / 80.0, 0.0, 1.0)
	for i in range(29):
		var x := 302 + (i * 17) % 106
		var y := 184 + (i * 11) % 8
		var heat := 0.5 + sin(phase * 3.0 + float(i)) * 0.4
		_pixel_rect(x, y, 4, 2, Color(0.95, 0.23 + 0.45 * heat * intensity, 0.08, 0.40 + intensity * 0.6))
	if intensity <= 0.04:
		return
	for i in range(16):
		var x := 301.0 + float(i) * 7.0
		var flutter := sin(phase * (5.0 + float(i % 3)) + float(i * 13))
		var height := (5.0 + 13.0 * intensity + flutter * 4.0) * intensity
		var tips := PackedVector2Array([Vector2(x - 3, 185), Vector2(x + 2, 185 - height), Vector2(x + 5, 185)])
		draw_colored_polygon(tips, Color(1.0, 0.42 + intensity * 0.28, 0.08, 0.68 * intensity))
		if i % 2 == 0:
			_pixel_rect(x, 183 - height * 0.46, 2, 3, Color(1.0, 0.86, 0.36, 0.67 * intensity))

func _draw_skewer() -> void:
	if state.current_food == "":
		return
	var target: float = state.current_target
	var degree: float = maxf(state.side_a, state.side_b) / maxf(target, 0.1)
	var burned: bool = degree > 2.1
	var raw := Color(state.food_color)
	var cooked := Color("#9a4d29")
	var dark := Color("#32231e")
	var t: float = clampf((state.side_a + state.side_b) / (target * 2.0), 0.0, 1.0)
	var meat_color: Color = raw.lerp(cooked, t)
	if burned:
		meat_color = dark
	for row in range(2):
		var y := 167 + row * 9
		draw_line(Vector2(290, y), Vector2(425, y + 2), Color("#d3d1c6"), 2.0)
		for piece in range(5):
			var x := 307 + piece * 19 + row * 2
			_pixel_rect(x - 1, y - 5, 13, 9, Color("#34251e"))
			_pixel_rect(x, y - 5, 11, 7, meat_color)
			_pixel_rect(x + 2, y - 4, 4, 2, meat_color.lightened(0.22))
			if state.food_is_vegetable:
				_pixel_rect(x + 8, y - 3, 3, 5, Color("#56804a"))
			if t > 0.36:
				_pixel_rect(x + 4, y, 4, 1, Color("#38241e"))

func _draw_cigarette() -> void:
	if state.cigarette_left <= 0.0:
		return
	var tip := Vector2(167, 156)
	draw_line(Vector2(163, 158), tip, Color("#e4ded0"), 2.0)
	_pixel_rect(167, 155, 2, 2, Color("#ffb04e"))
	if sin(phase * 8.0) > 0.3:
		_pixel_rect(169, 155, 1, 2, Color("#fff1a2"))

func _draw_smoke() -> void:
	for p in smoke_particles:
		var f: float = float(p["life"]) / float(p["max"])
		var color := Color(0.78, 0.85, 0.87, (1.0 - f) * 0.30)
		_pixel_rect(float(p["x"]) + sin(phase * 2.0 + f * 9.0) * 3.0, float(p["y"]), 3.0 + f * 3.0, 2.0 + f * 3.0, color)
