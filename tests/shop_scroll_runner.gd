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
	game.state.money = 100000000
	game.state.run_earned = 100000000
	game.state.prestige_points = 100
	game.state.talents.fortune = 1
	for id in game.registry.dice:
		game.state.add_die(id, Vector2(300,300))
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var failures: int = 0
	for page in ["Dice", "Upgrades", "Helpers", "Fate"]:
		main.shop.show_page(page)
		await process_frame
		await process_frame
		main.shop.scroll.scroll_vertical = 10000
		await process_frame
		var row: Dictionary = main.shop.rows.back()
		var button: Button = row.button
		var old_text: String = button.text
		var old_scroll: int = main.shop.scroll.scroll_vertical
		button.grab_focus()
		if button.disabled or old_scroll <= 0:
			push_error("Invalid purchase test fixture: " + page)
			failures += 1
		button.pressed.emit()
		await process_frame
		await process_frame
		if not is_instance_valid(button) or main.shop.scroll.scroll_vertical != old_scroll or button.text == old_text or not button.has_focus():
			push_error("Purchase lost scroll/focus or failed to refresh: " + page)
			failures += 1
	main.shop.show_page("Settings")
	await process_frame
	await process_frame
	main.shop.scroll.scroll_vertical = 120
	await process_frame
	var previous: int = main.shop.scroll.scroll_vertical
	main.shop.body.get_node("SettingsPage/particles").pressed.emit()
	await process_frame
	await process_frame
	if main.shop.scroll.scroll_vertical != previous:
		failures += 1
	print("SHOP SCROLL: ", failures, " failures; purchases across four pages and Settings toggle")
	quit(1 if failures else 0)
