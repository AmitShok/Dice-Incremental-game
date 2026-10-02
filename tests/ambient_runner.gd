extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		quit(1)
		return
	var manager: Node = root.get_node("GameManager")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var ambience: Node2D = main.get_node("Tabletop/Ambience")
	await create_timer(0.45).timeout
	check(ambience.left_flame.frame != 0 and ambience.steam.frame != 0 and ambience.plant.frame != 0, "Ambient loops advance")
	check(ambience.steam.visible, "Steam visible with motion enabled")
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	await RenderingServer.frame_post_draw
	if not folder.is_empty():
		root.get_texture().get_image().save_png(folder.path_join("ambient-table.png"))
	manager.session.state.settings.motion = false
	await process_frame
	await process_frame
	check(ambience.left_flame.frame == 0 and ambience.right_flame.frame == 0 and ambience.plant.frame == 0 and not ambience.steam.visible, "Reduced motion keeps candles and plant static, hides steam")
	manager.session.state.settings.motion = true
	manager.session.paused = true
	var before: float = ambience.elapsed
	await create_timer(0.2).timeout
	check(ambience.elapsed == before, "Developer pause freezes ambience")
	manager.session.paused = false
	await create_timer(0.4).timeout
	check(ambience.elapsed > before and ambience.steam.visible, "Motion resumes")
	check(manager.session.state.money == 0 and manager.session.pending.is_empty(), "Ambience never changes game economy")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Test audio remains silent")
	print("AMBIENT RESULT: ", failures, " failures")
	quit(1 if failures else 0)
