extends Control
## Tiny, non-interactive pixel meter: no Theme or minimum-size from ProgressBar.
## Works for both radio reception and food progress.

var value: float = 0.0:
	set(next):
		value = clampf(next, 0.0, 100.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	queue_redraw()

func _draw() -> void:
	var width: float = maxf(12.0, size.x)
	var height: float = maxf(6.0, size.y)
	draw_rect(Rect2(0, 0, width, height), Color("#0c171d"))
	draw_rect(Rect2(1, 1, width - 2, height - 2), Color("#39474c"))
	var filled: int = int(roundf(value * 0.1))
	var usable_width: float = width - 5.0
	for i in range(10):
		var from_x: float = 3.0 + floorf(usable_width * float(i) / 10.0)
		var to_x: float = 3.0 + floorf(usable_width * float(i + 1) / 10.0) - 1.0
		if to_x > from_x:
			var color: Color = Color("#e7ae65") if i < filled else Color("#26363b")
			draw_rect(Rect2(from_x, 2.0, to_x - from_x, height - 4.0), color)
