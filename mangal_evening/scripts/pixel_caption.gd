extends Control
## A fixed-height pixel caption drawn directly to the CanvasItem.
## Unlike native Label, the font never forces its rect to grow beyond the HUD.

var text := "":
	set(value):
		text = value
		queue_redraw()
var font: Font
var font_size := 10
var font_color := Color("#f2ddbc")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	queue_redraw()

func _draw() -> void:
	if font == null or text == "":
		return
	var display: String = text.replace("\n", " ")
	var available_width: float = maxf(0.0, size.x - 2.0)
	if available_width < 6.0:
		return
	if font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		# Clip at a word boundary if possible, always keep an ellipsis visible.
		var cutoff := display.length()
		while cutoff > 3 and font.get_string_size(display.substr(0, cutoff) + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
			cutoff -= 1
		var end_space: int = display.rfind(" ", cutoff)
		if end_space >= maxi(3, cutoff - 14):
			cutoff = end_space
		display = display.substr(0, cutoff).strip_edges() + "..."
	var baseline: float = minf(size.y - 1.0, float(font_size) + 0.5)
	draw_string(font, Vector2(0.0, baseline), display, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, font_color)
