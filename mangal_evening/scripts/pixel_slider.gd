extends Control
## Drawn pixel slider with genuine pointer/touch input and keyboard arrows.
signal value_changed(new_value: float)

var min_value := 0.0
var max_value := 1.0
var step := 0.05
var value := 0.5
var dragging := false
var ticks := 9

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(45, 18)
	queue_redraw()

func set_value_no_signal(v: float) -> void:
	value = _snap(v)
	queue_redraw()

func _snap(v: float) -> float:
	var s: float = maxf(step, 0.00001)
	return clampf(snappedf(v, s), min_value, max_value)

func _set_value_from_x(x: float) -> void:
	var width: float = maxf(size.x - 16.0, 1.0)
	var factor: float = clampf((x - 8.0) / width, 0.0, 1.0)
	var next: float = _snap(lerpf(min_value, max_value, factor))
	if not is_equal_approx(next, value):
		value = next
		value_changed.emit(value)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				_set_value_from_x(event.position.x)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust(step)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust(-step)
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		_set_value_from_x(event.position.x)
		accept_event()
	elif event is InputEventScreenTouch:
		dragging = event.pressed
		if dragging:
			_set_value_from_x(event.position.x)
		accept_event()
	elif event is InputEventScreenDrag and dragging:
		_set_value_from_x(event.position.x)
		accept_event()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT or event.keycode == KEY_DOWN:
			_adjust(-step)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_UP:
			_adjust(step)

func _adjust(amount: float) -> void:
	var next: float = _snap(value + amount)
	if not is_equal_approx(next, value):
		value = next
		value_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var cy := roundf(size.y * 0.5)
	var left := 8.0
	var span := maxf(size.x - 16.0, 1.0)
	var ratio: float = clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	draw_rect(Rect2(4, cy - 4, size.x - 8, 8), Color("#111d23"))
	draw_rect(Rect2(left, cy - 2, span, 4), Color("#3a4d51"))
	draw_rect(Rect2(left, cy - 2, span * ratio, 4), Color("#e4a35e"))
	for i in range(ticks):
		var x := left + span * float(i) / float(maxi(ticks - 1, 1))
		draw_rect(Rect2(roundf(x), cy + 6, 1, 2), Color("#819298"))
	var knob: float = left + span * ratio
	draw_rect(Rect2(roundf(knob) - 5, cy - 8, 10, 15), Color("#14232b"))
	draw_rect(Rect2(roundf(knob) - 3, cy - 7, 6, 13), Color("#e6c38c"))
	draw_rect(Rect2(roundf(knob) - 1, cy - 5, 2, 9), Color("#6c6256"))
