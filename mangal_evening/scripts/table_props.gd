extends Node2D
## Each independent tabletop sprite has its own location and texture.
const BASE := "res://assets/scene_layers/"
const ACTIONS := {
	"Plate": "plate", "Cup": "cup", "Cigarettes": "cigarettes",
	"Ashtray": "ashtray", "Kettle": "kettle", "Sauces": "sauce"
}
var state = null
var _shown: Dictionary = {}

func _process(_delta: float) -> void:
	if state == null:
		return
	_variant("Plate", "plate_full" if state.plated_food != "" else "plate")
	_variant("Cup", "cup_tea" if state.cup_filled else "cup")
	_variant("Kettle", "kettle_steam" if state.kettle_brewing > 0.0 else "kettle")
	_variant("Ashtray", "ashtray_full" if state.ashtray_ash > 0 else "ashtray")
	var pack: Sprite2D = get_node("Cigarettes")
	pack.modulate = Color(0.66, 0.66, 0.66) if state.cigarettes_in_pack <= 0 else Color.WHITE

func _variant(node_name: String, asset_name: String) -> void:
	if _shown.get(node_name, "") == asset_name:
		return
	var sprite: Sprite2D = get_node(node_name)
	sprite.texture = load(BASE + asset_name + ".png")
	_shown[node_name] = asset_name

func hit_test(world_point: Vector2) -> String:
	for name in ["Cup", "Kettle", "Cigarettes", "Ashtray", "Plate", "Sauces"]:
		var sprite: Sprite2D = get_node(name)
		if sprite.texture == null:
			continue
		var bounds: Rect2 = Rect2(sprite.global_position, sprite.texture.get_size() * sprite.global_scale)
		if bounds.has_point(world_point):
			return String(ACTIONS[name])
	return ""
