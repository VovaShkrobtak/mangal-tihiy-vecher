extends Control
## A clickable/drag-able analogue tuning knob. Also supports mouse wheel and touch.
signal turned(mhz: float)

const START_ANGLE := 2.35619449
const END_ANGLE := 7.06858347
const MIN_MHZ := 87.5
const MAX_MHZ := 108.0

var frequency := 93.7
var dragging := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "Крути пальцем/мышью или колесом — настройка частоты"
	queue_redraw()

func set_frequency(mhz: float) -> void:
	frequency = clampf(snappedf(mhz, 0.1), MIN_MHZ, MAX_MHZ)
	queue_redraw()

func _adjust(mhz_delta: float) -> void:
	var updated: float = clampf(snappedf(frequency + mhz_delta, 0.1), MIN_MHZ, MAX_MHZ)
	if not is_equal_approx(updated, frequency):
		set_frequency(updated)
		turned.emit(frequency)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust(0.1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust(-0.1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		_adjust((event.relative.x - event.relative.y) * 0.08)
		accept_event()
	elif event is InputEventScreenTouch:
		dragging = event.pressed
		accept_event()
	elif event is InputEventScreenDrag and dragging:
		_adjust((event.relative.x - event.relative.y) * 0.08)
		accept_event()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT or event.keycode == KEY_DOWN:
			_adjust(-0.1)
			accept_event()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_UP:
			_adjust(0.1)
			accept_event()

func _draw() -> void:
	var c := size * 0.5
	var radius := minf(size.x, size.y) * 0.39
	draw_circle(c + Vector2(1.0, 2.0), radius + 3.0, Color("#142029"))
	draw_circle(c, radius + 3.0, Color("#937c64"))
	draw_circle(c, radius + 1.0, Color("#2b3a40"))
	draw_circle(c, radius - 3.0, Color("#526067"))
	draw_circle(c - Vector2(1, 2), radius * 0.57, Color("#68747a"))
	draw_circle(c, radius * 0.50, Color("#27373b"))
	for i in range(17):
		var angle: float = START_ANGLE + (END_ANGLE - START_ANGLE) * float(i) / 16.0
		var unit := Vector2(cos(angle), sin(angle))
		draw_line(c + unit * (radius - 1), c + unit * (radius + 2), Color("#e7c38a"), 1.0)
	var fraction: float = (frequency - MIN_MHZ) / (MAX_MHZ - MIN_MHZ)
	var pointer_angle := START_ANGLE + fraction * (END_ANGLE - START_ANGLE)
	var pointer := Vector2(cos(pointer_angle), sin(pointer_angle))
	draw_line(c + pointer * radius * 0.30, c + pointer * radius * 0.80, Color("#ffd080"), 3.0)
	draw_circle(c, 3.0, Color("#d7b780"))
