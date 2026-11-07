extends Node2D
## Independent visual atmosphere: dusk, night lights, grill glow and embers.
var state = null
var elapsed := 0.0
var sparks: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func _process(delta: float) -> void:
	elapsed += delta
	if state == null:
		return
	var strength: float = state.glow_factor()
	if strength > 0.15 and sparks.size() < 22 and rng.randf() < delta * (1.0 + strength * 3.2):
		sparks.append({
			"pos": Vector2(rng.randf_range(310.0, 400.0), rng.randf_range(173.0, 183.0)),
			"vel": Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-29.0, -12.0)),
			"age": 0.0,
			"ttl": rng.randf_range(0.6, 1.2)
		})
	for s in sparks:
		s["age"] = float(s["age"]) + delta
		s["pos"] = Vector2(s["pos"]) + Vector2(s["vel"]) * delta
		s["vel"] = Vector2(s["vel"]) + Vector2(0.0, 12.0) * delta
	for i in range(sparks.size() - 1, -1, -1):
		if float(sparks[i]["age"]) >= float(sparks[i]["ttl"]):
			sparks.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if state == null:
		return
	var night: float = state.night_factor()
	var glow: float = state.glow_factor()
	draw_rect(Rect2(0, 0, 640, 247), Color(0.02, 0.04, 0.12, 0.08 + night * 0.24))
	if night < 0.65:
		draw_rect(Rect2(0, 0, 640, 115), Color(0.75, 0.26, 0.13, (0.65 - night) * 0.07))
	_draw_moon(night)
	_draw_windows(night)
	_draw_garland(night)
	_draw_firelight(glow)
	_draw_sparks()

func _draw_moon(night: float) -> void:
	var p := Vector2(509, 49)
	draw_circle(p, 27.0, Color(0.85, 0.89, 1.0, 0.025 + night * 0.035))
	draw_circle(p, 19.0, Color(1.0, 0.96, 0.73, 0.04 + night * 0.04))

func _draw_windows(night: float) -> void:
	if night < 0.1:
		return
	var flicker := 0.86 + 0.14 * sin(elapsed * 0.7)
	draw_rect(Rect2(471, 154, 22, 28), Color(1.0, 0.67, 0.30, night * 0.13 * flicker))
	draw_rect(Rect2(467, 151, 30, 35), Color(1.0, 0.72, 0.39, night * 0.045 * flicker))
	draw_rect(Rect2(76, 142, 9, 15), Color(1.0, 0.68, 0.30, night * 0.10))

func _draw_garland(night: float) -> void:
	var lights := [
		Vector2(36, 92), Vector2(81, 99), Vector2(128, 105),
		Vector2(178, 115), Vector2(239, 110), Vector2(298, 98),
		Vector2(359, 89), Vector2(424, 93), Vector2(485, 98),
		Vector2(552, 106)
	]
	for i in range(lights.size()):
		var p: Vector2 = lights[i]
		var pulse := 0.7 + 0.3 * maxf(0.0, sin(elapsed * (1.3 + float(i) * 0.04) + float(i)))
		draw_circle(p, 6.0, Color(1.0, 0.75, 0.31, (0.025 + night * 0.045) * pulse))
		draw_circle(p, 2.5, Color(1.0, 0.91, 0.59, 0.05 * pulse))

func _draw_firelight(glow: float) -> void:
	if glow <= 0.01:
		return
	var flicker := 0.89 + 0.11 * sin(elapsed * 6.2) * sin(elapsed * 2.7)
	var strength := glow * flicker
	draw_circle(Vector2(351, 181), 79.0, Color(1.0, 0.42, 0.10, 0.050 * strength))
	draw_circle(Vector2(351, 181), 47.0, Color(1.0, 0.64, 0.20, 0.13 * strength))
	draw_rect(Rect2(290, 192, 127, 17), Color(1.0, 0.48, 0.10, 0.065 * strength))
	draw_circle(Vector2(258, 180), 48.0, Color(1.0, 0.56, 0.23, 0.045 * strength))
	draw_circle(Vector2(169, 162), 29.0, Color(1.0, 0.55, 0.23, 0.023 * strength))

func _draw_sparks() -> void:
	for s in sparks:
		var age: float = float(s["age"])
		var life: float = float(s["ttl"])
		var remaining := clampf(1.0 - age / maxf(life, 0.01), 0.0, 1.0)
		var p: Vector2 = s["pos"]
		draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(1.0, 0.76, 0.32, remaining * 0.88))
