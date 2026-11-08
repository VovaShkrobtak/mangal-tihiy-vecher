extends Node2D
## A single LED animation; the receiver body is a separate Sprite2D.
var radio = null
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if radio == null:
		return
	if radio.is_on:
		var tint: Color = Color("#8adea6") if radio.active_station >= 0 else Color("#da7656")
		draw_rect(Rect2(36, 38, 4, 2), tint)
		var glow: float = 0.07 + maxf(0.0, sin(elapsed * 2.6)) * 0.07
		draw_rect(Rect2(35, 37, 6, 4), Color(1.0, 0.85, 0.40, glow))
	else:
		draw_rect(Rect2(36, 38, 4, 2), Color("#4e514b"))
