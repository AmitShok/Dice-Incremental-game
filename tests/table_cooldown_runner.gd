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
	manager.set_process(false)
	var game: GameSession = manager.session
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var button: Button = main.get_node("HUD/RollButton")
	button.pressed.emit()
	await process_frame
	await process_frame
	check(game.state.table_roll_remaining == 60 and button.disabled and button.caption.text.ends_with("1:00") and button.fill.value == 0, "Starts full minute with empty bar")
	var next_roll: int = game.next_roll
	button.pressed.emit()
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	main._unhandled_key_input(space)
	check(game.next_roll == next_roll, "Button and Space cannot bypass cooldown")
	game.tick(30)
	await process_frame
	await process_frame
	check(button.caption.text.ends_with("0:30") and button.fill.value == 30, "Halfway time and progress agree")
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	if not folder.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("roll-cooldown.png"))
	var restored: GameState = GameState.restore(game.state.snapshot(), game.registry)
	check(restored != null and restored.table_roll_remaining == 30, "Cooldown saves and restores")
	var reloaded := GameSession.new(game.registry, restored)
	reloaded.offline(5)
	check(reloaded.state.table_roll_remaining == 25, "Offline time reduces remaining cooldown")
	game.state.dice[0].cooldown = 0
	check(game.request_roll([game.state.dice[0].id]), "Individual roll still works during table cooldown")
	game.paused = true
	game.tick(5)
	check(game.state.table_roll_remaining == 30, "Pause freezes cooldown")
	game.paused = false
	game.tick(29.5)
	await process_frame
	await process_frame
	check(button.disabled and button.caption.text.ends_with("0:01"), "Last fractional second stays disabled")
	game.tick(0.5)
	await process_frame
	await process_frame
	check(not button.disabled and button.fill.value == 60 and button.caption.text.contains("SPACE"), "Ready at exactly 60 seconds")
	main._unhandled_key_input(space)
	check(game.state.table_roll_remaining == 60, "Space starts the next cooldown")
	var old: Dictionary = game.state.snapshot()
	old.erase("table_roll_remaining")
	check(GameState.restore(old, game.registry).table_roll_remaining == 0, "Older saves start ready")
	old.table_roll_remaining = -1
	check(GameState.restore(old, game.registry) == null, "Invalid saved cooldown rejected")
	var busy := GameSession.new(game.registry)
	busy.request_roll([busy.state.dice[0].id])
	check(not busy.roll_table() and busy.state.table_roll_remaining == 0, "No cooldown consumed when no die can roll")
	print("TABLE COOLDOWN: ", failures, " failures")
	quit(1 if failures else 0)
