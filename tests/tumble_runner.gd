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
	var game: GameSession = root.get_node("GameManager").session
	root.get_node("GameManager").set_process(false)
	game.state.dice.clear()
	game.state.counts.clear()
	var ids: Array = []
	for id in game.registry.dice:
		var index: int = ids.size()
		var die: DiceInstance = game.state.add_die(id, Vector2(150 + index % 5 * 115, 245 + int(index/5) * 135))
		ids.append(die.id)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	if main.visuals.size() != 10:
		push_error("Expected all ten die visuals to load")
		quit(1)
		return
	game.request_roll(ids)
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	for progress in [0.15, 0.38, 0.68, 0.95]:
		for visual: DiceVisual in main.visuals.values():
			visual.set_process(false)
			visual._update_roll_pose(progress)
			check(absf(visual.sprite.rotation) < 0.11, "No flat full-circle spin")
			if progress < 0.86:
				check(visual.sprite.texture == visual.definition.rolling_texture and visual.sprite.hframes == 24, "Uses shaded tumble frames")
			else:
				check(visual.sprite.texture == visual.definition.texture and visual.sprite.frame == visual.result_face, "Reveals reserved face")
		await RenderingServer.frame_post_draw
		if not folder.is_empty():
			root.get_texture().get_image().save_png(folder.path_join("tumble-%d.png" % int(progress * 100)))
	game.settle()
	for visual: DiceVisual in main.visuals.values():
		check(visual.sprite.frame == visual.die.face - 1 and visual.sprite.position == Vector2(32,28) and not visual.is_processing(), "Lands cleanly and stops processing")
	game.state.settings.motion = false
	for die in game.state.dice:
		die.cooldown = 0
	game.request_roll(ids)
	for visual: DiceVisual in main.visuals.values():
		var before: Vector2 = visual.position
		visual.set_process(false)
		visual._update_roll_pose(0.5)
		check(visual.position == before and visual.sprite.rotation == 0 and visual.sprite.texture == visual.definition.texture, "Reduced motion stays still")
	game.settle()
	print("TUMBLE RESULT: ", failures, " failures across all 10 dice")
	quit(1 if failures else 0)
