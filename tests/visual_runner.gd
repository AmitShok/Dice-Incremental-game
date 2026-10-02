extends SceneTree

var phase: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		push_error("Visual integration requires --test")
		quit(1)
		return
	var game: GameSession = root.get_node("GameManager").session
	confirm_not_reset(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))
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
	# Scene-authored layout and extra editor nodes must survive _ready().
	var editor_marker := Node.new()
	editor_marker.name = "EditorAddedNode"
	main.add_child(editor_marker)
	main.get_node("HUD/Wallet").position.x += 3
	root.add_child(main)
	await process_frame
	await process_frame
	confirm_not_reset(is_instance_valid(editor_marker) and editor_marker.get_parent() == main)
	confirm_not_reset(is_equal_approx(main.wallet.position.x, 457.0))
	main.wallet.position.x -= 3
	confirm_not_reset(main.shop.position.is_equal_approx(Vector2(792, 94)))
	var first: DiceVisual = main.visuals[game.state.dice[0].id]
	confirm_not_reset(first.scale.is_equal_approx(Vector2(0.65, 0.65)))
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
		var group: String = "Footer" if title in ["Ledger", "Settings"] else "Tabs"
		main.shop.get_node(group + "/" + title).pressed.emit()
		await process_frame
		confirm_not_reset(main.shop.page == title)
		checks += 1
	var old_sound: bool = game.state.settings.sound
	main.shop.body.get_node("SettingsPage/DeveloperTools").pressed.emit()
	confirm_not_reset(main.debug_panel.visible)
	var before_debug_credit: float = game.state.money
	main.debug_panel.get_node("Layout/Scroll/Buttons/Action0").pressed.emit()
	confirm_not_reset(game.state.money == before_debug_credit + 1000)
	await process_frame
	await process_frame
	var developer_scroll: ScrollContainer = main.debug_panel.get_node("Layout/Scroll")
	developer_scroll.scroll_vertical = 10000
	await process_frame
	await process_frame
	var last_tool: Button = developer_scroll.get_node("Buttons/Action9")
	confirm_not_reset(developer_scroll.scroll_vertical > 0)
	confirm_not_reset(developer_scroll.get_global_rect().encloses(last_tool.get_global_rect()))
	confirm_not_reset(main.debug_panel.get_global_rect().end.y <= 640)
	var tool_point: Vector2 = root.get_final_transform() * last_tool.get_global_rect().get_center()
	for expected_pause in [true, false]:
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = pressed
			click.position = tool_point
			click.global_position = tool_point
			root.push_input(click, false)
		confirm_not_reset(game.paused == expected_pause)
	var developer_capture: String = OS.get_environment("DICE_TEST_OUTPUT")
	if not developer_capture.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(developer_capture.path_join("developer-tools-scrolled.png"))
	main.debug_panel.get_node("Layout/Close").pressed.emit()
	confirm_not_reset(not main.debug_panel.visible)
	main.shop.body.get_node("SettingsPage/sound").pressed.emit()
	confirm_not_reset(game.state.settings.sound != old_sound)
	main.shop.body.get_node("SettingsPage/sound").pressed.emit()
	confirm_not_reset(game.state.settings.sound == old_sound)
	confirm_not_reset(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))
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
	main.get_node("HUD/RollButton").pressed.emit()
	confirm_not_reset(not game.pending.is_empty())
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
	var rolling_die: DiceInstance = game.state.dice[0]
	var rolling_visual: DiceVisual = main.visuals[rolling_die.id]
	var roll_origin: Vector2 = rolling_visual.position
	rolling_die.cooldown = 0
	game.request_roll([rolling_die.id])
	await create_timer(0.15).timeout
	confirm_not_reset(rolling_visual.position.distance_to(roll_origin) > 0.1)
	await create_timer(1.5).timeout
	confirm_not_reset((rolling_visual.position + Vector2(32,32) * rolling_visual.scale).is_equal_approx(rolling_die.position))
	print("SCATTER: visible travel and saved landing match")
	main.queue_free()
	await process_frame
	var disabled_main: Control = load("res://scenes/main.tscn").instantiate()
	disabled_main.developer_tools_enabled = false
	root.add_child(disabled_main)
	disabled_main.shop.show_page("Settings")
	confirm_not_reset(disabled_main.debug_panel == null and not disabled_main.shop.body.get_node("SettingsPage/DeveloperTools").visible)
	print("DEVELOPER TOOLS: settings open/close and credit tested; release switch hides access")
	quit()

func confirm_not_reset(condition: bool) -> void:
	if not condition:
		push_error("Visual integration assertion failed")
		quit(1)
