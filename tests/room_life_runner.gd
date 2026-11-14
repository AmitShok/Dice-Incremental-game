extends SceneTree
## Room life: idle motion, every reaction, and the motion / flashes / particles / pause rules.
## Saves captures mid-reaction to DICE_TEST_OUTPUT when it is set.

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await process_frame

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		quit(1)
		return
	var manager: Node = root.get_node("GameManager")
	manager.set_process(false)
	var game: GameSession = manager.session
	game.state.chips = 20
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var life: RoomLife = main.room_life
	var table: Node2D = main.get_node("Tabletop")
	var money: float = game.state.money
	await frames(3)
	check(life != null and life.get_parent() == table and life.get_index() < table.get_node("Dice").get_index(), "Room life sits under the dice")
	check(life.motes.size() == 26 and life.shown_chips == 5, "Dust motes exist and the chip stack tracks chips held")
	var before: Vector2 = life.motes[0].pos
	await create_timer(0.3).timeout
	check(life.motes[0].pos != before, "Dust drifts")

	# Natural 1: a chip drops onto the stack.
	game.state.chips = 24
	life.on_land(Vector2(300, 300), true)
	check(life.chip_drop >= 0.0 and life.puffs.size() == 5, "A natural 1 drops a chip; landings puff felt dust")
	await create_timer(0.5).timeout
	check(life.chip_drop < 0.0 and life.shown_chips == 6 and life.puffs.is_empty(), "Chip settles and dust fades")

	# Streak, gust, combo glint and thump, big roll glint, milestone page flip.
	game.streak = 100
	game.streak_timer = 60.0
	life.on_streak(4)
	life.on_table_roll()
	life.on_combo()
	life.on_big_roll()
	life.on_milestone()
	life.on_land(Vector2(420, 260), false)
	await frames(6)
	var flame: Sprite2D = life.flames[0]
	check(flame.scale.y > 2.4 and flame.modulate.b > 1.2 and absf(flame.skew) > 0.0, "Flames grow, turn blue-white at INFINITE and lean in the gust")
	check(life.glints.size() == 2 and life.page_flip >= 0.0, "Combo and big roll glint; milestone flips the ledger")
	check(table.position != life.thump_base or life.thump > 0.0, "Combo thumps the table")
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	await RenderingServer.frame_post_draw
	if not folder.is_empty():
		root.get_texture().get_image().save_png(folder.path_join("room-life-reacting.png"))
	await create_timer(0.8).timeout
	check(table.position == life.thump_base and life.glints.is_empty() and life.page_flip < 0.0, "Reactions finish and the table returns home")
	check(is_equal_approx(life.flames[0].position.y, RoomLife.CANDLES[0].y), "Flames stay pinned to their wicks")

	# Settings: reduced motion, no flashes, no particles.
	game.state.settings.motion = false
	game.state.settings.flashes = false
	life.on_combo()
	life.on_big_roll()
	life.on_table_roll()
	life.on_land(Vector2(300, 300), true)
	await frames(3)
	check(life.thump == 0.0 and life.glints.is_empty() and life.gust == 0.0 and life.puffs.is_empty(), "Reduced motion and no flashes skip thumps, glints, gusts and puffs")
	check(flame.scale == Vector2(2, 2) and flame.skew == 0.0, "Reduced motion keeps flames still")
	game.state.settings.motion = true
	game.state.settings.flashes = true
	game.state.settings.particles = false
	life.on_land(Vector2(300, 300), false)
	check(life.puffs.is_empty(), "Particles off skips felt dust")
	game.state.settings.particles = true

	# Pause freezes everything.
	game.paused = true
	var frozen: float = life.time
	await create_timer(0.2).timeout
	check(life.time == frozen, "Pause freezes room life")
	game.paused = false
	check(game.state.money == money, "Room life never changes the economy")
	print("ROOM LIFE: ", failures, " failures")
	quit(1 if failures else 0)
