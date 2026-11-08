extends SceneTree
## Renders actual game frames on Xvfb: useful for catching regressions
## that geometry tests alone cannot see.
func _initialize() -> void:
	call_deferred("make_previews")

func make_previews() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		push_error("Visual capture: scene missing")
		quit(1)
		return
	var game: Node = scene.instantiate()
	root.add_child(game)
	var folder := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(folder)
	await process_frame
	var hud: Control = game.get_node("HUD")
	for index in range(4):
		hud.call("set_tab", index)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		if image.is_empty():
			push_error("Visual capture: empty frame for tab %d" % index)
			quit(1)
			return
		var path: String = "res://artifacts/hud_%d.png" % index
		var result: Error = image.save_png(path)
		if result != OK:
			push_error("Visual capture: cannot write tab %d" % index)
			quit(1)
			return
		print("HUD_PREVIEW_SAVED: " + path + " %dx%d" % [image.get_width(), image.get_height()])
	quit(0)
