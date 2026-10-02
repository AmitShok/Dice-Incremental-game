extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		quit(1)
		return
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	for dimensions in [Vector2i(640,360), Vector2i(800,800), Vector2i(1400,700), Vector2i(1120,640)]:
		root.size = dimensions
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		var logical: Vector2 = root.get_visible_rect().size
		var transform: Transform2D = root.get_final_transform()
		print("RESIZE ", root.size, " logical=", logical, " transform=", transform)
		check(logical.is_equal_approx(Vector2(1120,640)), "Logical layout changed at " + str(dimensions))
		# Letterbox dimensions round to physical pixels, so allow one pixel of error.
		var expected_scale: float = minf(root.size.x / 1120.0, root.size.y / 640.0)
		check(absf(transform.x.length() - expected_scale) * 1120 <= 1.01 and absf(transform.y.length() - expected_scale) * 640 <= 1.01, "Incorrect aspect scaling at " + str(dimensions))
		var bottom_right: Vector2 = transform * Vector2(1120,640)
		check(bottom_right.x <= root.size.x + 1 and bottom_right.y <= root.size.y + 1 and transform.origin.x >= -1 and transform.origin.y >= -1, "Game clips window at " + str(dimensions))
		var settings_button: Button = main.shop.get_node("Footer/Settings")
		var point: Vector2 = transform * settings_button.get_global_rect().get_center()
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			click.position = point
			click.global_position = point
			root.push_input(click, false)
		await process_frame
		check(main.shop.page == "Settings", "Scaled Settings click missed at " + str(dimensions))
		main.shop.show_page("Dice")
		if not folder.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("resize-%dx%d.png" % [dimensions.x, dimensions.y]))
	print("RESIZE RESULT: ", failures, " failures")
	quit(1 if failures else 0)
