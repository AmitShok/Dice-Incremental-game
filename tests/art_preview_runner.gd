extends SceneTree
## Renders every table surface plus a rolling frame to DICE_TEST_OUTPUT for art review.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if not OS.get_cmdline_user_args().has("--test") or OS.get_environment("DICE_TEST_OUTPUT").is_empty():
		push_error("Art preview needs --test and DICE_TEST_OUTPUT")
		quit(1)
		return
	var game: GameSession = root.get_node("GameManager").session
	game.state.money = 900000
	game.state.run_earned = 900000
	for id in ["d4", "d8", "d10", "d12", "d20", "golden_d6", "lucky_d6", "exploding_d6", "multiplier_d6", "spark_d8", "blast_d10", "gild_d12"]:
		game.progression.buy_die(id)
	for index in game.state.dice.size():
		game.state.dice[index].position = Vector2(120 + index % 6 * 110, 210 + int(index / 6) * 120)
	game.state.helpers = 4
	game.state.hats = ["cone", "tophat", "crown", "flower", "beret", "wizard", "halo", "cap"]
	game.state.crew_hat = "mix"
	game.state.tables = TableCatalog.TABLES.keys()
	game.state.dice[3].gilded = true
	game.state.upgrades.combos = 1
	game.state.chips = 40
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var out: String = OS.get_environment("DICE_TEST_OUTPUT")
	for table in TableCatalog.TABLES:
		game.select_table(table)
		main.refresh()
		for i in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("table-%s.png" % table))
	game.streak = 27
	game.streak_timer = 2.0
	main.shop.show_page("Tables")
	game.roll_table()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("rolling.png"))
	quit()
