extends SceneTree
## Automated scene smoke test for GitHub Actions.

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		push_error("Could not load main scene")
		quit(1)
		return
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	if main.get("food_picker") == null:
		push_error("Grill interface is missing")
		quit(1)
		return
	main.call("_start_food")
	if String(main.get("current_food")) == "":
		push_error("Grill did not accept a food choice")
		quit(1)
		return
	main.call("_flip_food")
	main.call("_take_food")
	main.call("_tune_preset", 3)
	main.call("_smoke")
	if float(main.get("cigarette_left")) < 1.0:
		push_error("Cigarette mechanic failed")
		quit(1)
		return
	print("PASS: scene loaded, food cooked/turned, radio tuned, cigarette action")
	quit(0)
