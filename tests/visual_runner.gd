extends SceneTree

var phase: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: GameSession = root.get_node("GameManager").session
	game.state.money = 90000
	game.state.run_earned = 100000
	for id in ["d4", "d8", "d10", "d12", "d20", "golden_d6", "lucky_d6", "exploding_d6", "multiplier_d6"]:
		game.progression.buy_die(id)
	game.state.helpers = 2
	game.state.upgrades.combos = 1
	game.state.upgrades.heavy = 2
	for index in game.state.dice.size():
		game.state.dice[index].position = Vector2(150 + index % 5 * 116, 245 + int(index / 5) * 135)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var first: DiceVisual = main.visuals[game.state.dice[0].id]
	var start: Vector2 = game.state.dice[0].position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = start
	first._gui_input(press)
	var movement := InputEventMouseMotion.new()
	movement.global_position = start + Vector2(40, 30)
	first._gui_input(movement)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.global_position = movement.global_position
	first._gui_input(release)
	confirm_not_reset(game.state.dice[0].position.is_equal_approx(start + Vector2(40, 30)) and not game.state.dice[0].busy)
	print("DRAG: movement committed without rolling")
	for title in ["Dice", "Upgrades", "Helpers", "Fate", "Ledger", "Settings"]:
		main.shop.show_page(title)
		await process_frame
		checks += 1
	main.shop.show_page("Dice")
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	if not folder.is_empty():
		root.get_texture().get_image().save_png(folder.path_join("table-progressed.png"))
	main.ask_prestige()
	await process_frame
	checks += 1
	confirm_not_reset(game.state.dice.size() == 10)
	main.confirm.hide()
	var ids: Array = []
	for die in game.state.dice:
		ids.append(die.id)
	game.request_roll(ids)
	await create_timer(1.4).timeout
	if not folder.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("table-rolling.png"))
	main.shop.show_page("Fate")
	await process_frame
	if not folder.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("fate-talents.png"))
	# Exercise the actual confirmation callback on an ephemeral test session.
	main.ask_prestige()
	main.confirm.confirmed.emit()
	main.confirm.hide()
	await process_frame
	confirm_not_reset(game.state.dice.size() == 1 and game.state.prestige_points >= 1)
	var success: bool = game.progression.buy_upgrade("fortune", true)
	confirm_not_reset(success)
	main.shop.show_page("Settings")
	await process_frame
	if not folder.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("settings.png"))
	print("VISUAL SMOKE: ", checks, " pages/confirmation checks; prestige and talent purchase passed")
	quit()

func confirm_not_reset(condition: bool) -> void:
	if not condition:
		push_error("Visual integration assertion failed")
		quit(1)
