extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		quit(1)
		return
	var manager: Node = root.get_node("GameManager")
	manager.set_process(false)
	var game: GameSession = manager.session
	game.state.chips = 500
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var failures: int = 0
	main.shop.show_page("Helpers")
	await process_frame
	await process_frame
	for attempt in 12:
		var button: Button = main.shop.capsule_button
		if button == null or not is_instance_valid(button):
			push_error("Capsule card vanished after pull %d" % attempt)
			failures += 1
			break
		var chips_before: int = game.state.chips
		button.pressed.emit()
		await process_frame
		await process_frame
		if game.state.chips >= chips_before:
			push_error("Capsule pull %d did not spend chips" % attempt)
			failures += 1
		if not main.shop.reveal.visible or main.shop.reveal.get_node("Prize").texture == null:
			push_error("Reveal not shown after pull %d" % attempt)
			failures += 1
		# The reveal is one short row; a tall one means the hat name wrapped letter by letter.
		if main.shop.reveal.size.y > 100:
			push_error("Reveal row is %d px tall after pull %d" % [main.shop.reveal.size.y, attempt])
			failures += 1
	print("CAPSULE: ", failures, " failures; hats ", game.state.hats.size(), ", chips ", game.state.chips)
	quit(1 if failures else 0)
