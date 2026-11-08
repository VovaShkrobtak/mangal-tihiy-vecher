extends Node2D
## Individual Node2D children are drawn independently and have movable hitboxes.
var state = null

const NAMES := {"cup":"Cup","kettle":"Kettle","cigarettes":"Cigarettes","ashtray":"Ashtray","plate":"Plate","sauce":"Sauces"}
const SIZES := {"cup":Vector2(26,30),"kettle":Vector2(38,41),"cigarettes":Vector2(27,24),"ashtray":Vector2(32,18),"plate":Vector2(45,18),"sauce":Vector2(27,29)}

func _process(_delta: float) -> void:
	for obj in get_children():
		obj.set("state", state)

func hitbox(key: String) -> Rect2:
	if not NAMES.has(key):
		return Rect2()
	var obj: Node2D = get_node_or_null(NAMES[key])
	if obj == null:
		return Rect2()
	return Rect2(obj.global_position - Vector2(4,4), SIZES[key]+Vector2(8,10))

func hit_test(p: Vector2) -> String:
	for key in ["cup","kettle","cigarettes","ashtray","plate","sauce"]:
		if hitbox(key).has_point(p):
			return key
	return ""
