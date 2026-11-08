extends Node2D
## Independent scenery/prop. Move each node in main.tscn to change its placement.
@export var object_kind := ""
var state = null
var radio = null
var clock := 0.0

func _process(delta: float) -> void:
	clock += delta
	if object_kind in ["radio", "cup", "kettle", "plate", "ashtray"]:
		queue_redraw()

func rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), w, h), c)

func _draw() -> void:
	match object_kind:
		"background_patch": draw_background_patch()
		"garages": draw_garages()
		"pole": draw_pole()
		"table_patch": draw_table_patch()
		"table": draw_table()
		"person": draw_person()
		"newspaper": draw_newspaper()
		"cup": draw_cup()
		"kettle": draw_kettle()
		"cigarettes": draw_cigarettes()
		"ashtray": draw_ashtray()
		"plate": draw_plate()
		"sauce": draw_sauce()
		"radio": draw_radio()

func draw_background_patch() -> void:
	# Old floating garage tops & pole are hidden before drawing grounded replacements.
	for y in range(73):
		var color := Color("#31374c") if y < 39 else Color("#344052") if y < 55 else Color("#2c413d")
		rect(0, float(y), 274, 1, color)
	draw_colored_polygon(PackedVector2Array([Vector2(0,57),Vector2(37,42),Vector2(81,56),Vector2(110,44),Vector2(164,61),Vector2(214,46),Vector2(274,56),Vector2(274,76),Vector2(0,76)]),Color("#293c47"))
	for i in range(16):
		rect(float((i*31)%269),70+float(i%4),8,2,Color("#44573b"))

func draw_garages() -> void:
	rect(-5,41,243,8,Color("#455341"))
	for i in range(4):
		var x: float = float(i*58)
		rect(x,0,56,43,Color("#585a62"))
		rect(x+2,3,52,37,Color("#7b7a82"))
		rect(x-1,-3,58,4,Color("#775a49"))
		rect(x+6,13,44,27,Color("#343942"))
		rect(x+9,16,38,22,Color("#444651"))
		for j in range(5):
			rect(x+11+float(j*7),16,1,21,Color("#85858e"))
		rect(x+40,28,3,2,Color("#b4b6aa"))
	rect(141,6,7,6,Color("#e6bb6e"))
	for i in range(26):
		rect(float((i*47)%233),43+float(i%4),3,2,Color("#576943"))

func draw_pole() -> void:
	rect(8,4,5,96,Color("#765135"))
	rect(10,6,2,90,Color("#a07448"))
	for y in [17,28]:
		rect(3,float(y),15,3,Color("#987044"))
		rect(4,float(y),2,2,Color("#d8c7a0"))
		rect(16,float(y),2,2,Color("#d8c7a0"))
	draw_line(Vector2(11,17),Vector2(-43,31),Color("#262d35"),1)
	draw_line(Vector2(11,28),Vector2(-41,36),Color("#262d35"),1)
	draw_line(Vector2(11,17),Vector2(70,36),Color("#262d35"),1)
	draw_line(Vector2(11,28),Vector2(70,44),Color("#262d35"),1)
	rect(4,96,17,3,Color("#456044"))

func draw_table_patch() -> void:
	# Opaque backdrop over the old crowded/overlapping baked-in tabletop.
	for y in range(106):
		var c := Color("#273f37") if y < 30 else Color("#304731") if y < 66 else Color("#263e28")
		rect(0,float(y),263,1,c)
	for i in range(12):
		var x: float = float(i*22)
		rect(x+7,26,8,43,Color("#76533b"))
		rect(x+9,23,4,4,Color("#8c6242"))
		rect(x,38,21,4,Color("#684931"))
	for i in range(24):
		rect(float((i*41)%259),77+float(i%18),3,2,Color("#4b6443"))

func draw_table() -> void:
	rect(0,25,260,11,Color("#9c7149"))
	rect(3,25,253,3,Color("#bd905b"))
	rect(0,36,260,4,Color("#755135"))
	for i in range(12):
		rect(8+float(i*21),29,12,1,Color("#78543c"))
	rect(16,40,11,46,Color("#795237"))
	rect(233,40,11,46,Color("#795237"))
	draw_line(Vector2(27,40),Vector2(79,80),Color("#745039"),4)
	draw_line(Vector2(234,40),Vector2(181,80),Color("#745039"),4)
	rect(18,70,92,6,Color("#81583c"))

func draw_person() -> void:
	rect(11,15,27,27,Color("#b68569"))
	rect(9,8,30,9,Color("#4c674d"))
	rect(15,2,21,8,Color("#445d46"))
	rect(29,29,8,5,Color("#7c4d3d"))
	rect(9,39,37,35,Color("#596e55"))
	rect(0,50,14,19,Color("#536950"))
	rect(41,49,14,18,Color("#576d51"))
	rect(8,72,17,24,Color("#293c4a"))
	rect(26,72,17,24,Color("#2d3b4a"))
	rect(3,94,25,5,Color("#353435"))
	rect(25,94,24,5,Color("#353435"))

func draw_newspaper() -> void:
	rect(0,3,43,15,Color("#cbbda5"))
	rect(1,2,41,13,Color("#eee4cd"))
	for y in [5,8,11]:
		for x in range(3,40,5):
			rect(float(x),float(y),3,1,Color("#908b7f"))
	rect(25,5,7,6,Color("#b3a58c"))

func draw_cup() -> void:
	rect(1,9,17,16,Color("#ccd4d1"))
	rect(3,8,13,16,Color("#ecede4"))
	rect(4,9,11,3,Color("#8b4b2d" if state != null and bool(state.cup_filled) else "#9fa7a3"))
	rect(18,12,5,8,Color("#e5e6dd"))
	rect(20,14,3,4,Color("#34454b"))
	if state != null and bool(state.cup_filled):
		rect(6+sin(clock)*2.0,2,2,5,Color(0.91,0.92,0.88,0.4))

func draw_kettle() -> void:
	rect(5,11,25,28,Color("#acbdb9"))
	rect(8,10,19,27,Color("#e4ebe6"))
	rect(11,6,14,4,Color("#527ea2"))
	rect(16,3,5,4,Color("#d8e3df"))
	rect(28,16,8,4,Color("#dce7e3"))
	rect(1,15,5,17,Color("#4c6375"))
	rect(30,16,4,14,Color("#596b76"))
	rect(5,37,25,3,Color("#54748a"))
	if state != null and float(state.kettle_brewing) > 0.0:
		rect(12+sin(clock)*2.0,0,2,4,Color(0.9,0.9,0.88,0.5))

func draw_cigarettes() -> void:
	rect(0,7,24,13,Color("#e1cbaa"))
	rect(0,7,24,5,Color("#b94c36"))
	rect(3,13,18,4,Color("#fff0d2"))
	if state != null and int(state.cigarettes_in_pack) > 0:
		for x in [5,9,13]:
			rect(float(x),2,3,10,Color("#eee8da"))

func draw_ashtray() -> void:
	rect(0,6,29,7,Color("#34393d"))
	rect(4,4,21,7,Color("#8c8a85"))
	rect(7,6,15,4,Color("#515557"))
	if state != null and int(state.ashtray_ash) > 0:
		for i in range(mini(int(state.ashtray_ash),5)):
			rect(8+i*3,5+i%2,3,2,Color("#c6bcb0"))
	if state != null and float(state.cigarette_left) > 0.0:
		rect(15,2,9,2,Color("#f4e9d8"))
		rect(24,2,2,2,Color("#ff9954"))

func draw_plate() -> void:
	rect(0,9,42,6,Color("#9c8367"))
	rect(3,5,36,8,Color("#ead7ba"))
	rect(7,7,28,4,Color("#f4e7cc"))
	if state != null and String(state.plated_food) != "":
		for i in range(5):
			rect(8+i*5,3+i%2,7,5,Color("#b05b33"))
		if String(state.plated_sauce) != "":
			rect(25,7,9,3,Color("#d6b849" if String(state.plated_sauce)=="Горчица" else "#bb4b32"))

func draw_sauce() -> void:
	var cols := [Color("#b13b2a"),Color("#d0b04f"),Color("#764028")]
	for i in range(3):
		var x: float = float(i*8)
		rect(x,4,7,22,Color("#292c2c"))
		rect(x+1,8,5,16,cols[i])
		rect(x+1,2,5,4,Color("#e0d0ad"))

func draw_radio() -> void:
	# Stand and receiver intentionally form ONE movable radio prop.
	rect(0,9,93,104,Color("#33432f"))
	rect(7,74,81,38,Color("#806349"))
	rect(12,79,72,28,Color("#6c523d"))
	draw_line(Vector2(13,81),Vector2(82,105),Color("#b09065"),2)
	draw_line(Vector2(82,81),Vector2(13,105),Color("#b09065"),2)
	rect(5,5,85,64,Color("#92704b"))
	rect(9,10,77,53,Color("#6f533a"))
	rect(15,17,18,20,Color("#c6ae83"))
	rect(63,17,18,20,Color("#c6ae83"))
	for i in range(5):
		rect(17+i*3,19,1,16,Color("#9b7e55"))
		rect(65+i*3,19,1,16,Color("#9b7e55"))
	var lit: bool = radio != null and bool(radio.is_on)
	rect(41,15,18,10,Color("#a1a66b" if lit else "#5d6852"))
	rect(44,18,12,3,Color("#dbe5a0" if lit else "#6e775f"))
	rect(40,30,21,9,Color("#28312e"))
	for i in range(4):
		rect(42+i*4,32,2,4,Color("#9ab99c" if lit else "#606d65"))
	for yy in [44,51]:
		for xx in range(16,82,10):
			rect(float(xx),float(yy),4,4,Color("#22282a"))
	rect(47,51,7,7,Color("#d7b680"))
	draw_line(Vector2(19,5),Vector2(14,-15),Color("#d9d5c8"))
	draw_line(Vector2(78,5),Vector2(82,-17),Color("#d9d5c8"))
