extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: GameSession = root.get_node("GameManager").session
	game.state.dice.clear()
	game.state.counts.clear()
	var count: int = 100
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--dice="):
			count = clampi(argument.trim_prefix("--dice=").to_int(), 1, 100)
	for index in count:
		game.state.add_die("d6", Vector2(85 + index % 11 * 61, 170 + int(index / 11) * 34))
	game.state.automatic.d6 = true
	game.state.helpers = 8
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var started: int = Time.get_ticks_msec()
	var frames: int = 0
	var worst_process: float = 0.0
	var cpu_samples: Array[float] = []
	var tick_samples: Array[float] = []
	while Time.get_ticks_msec() - started < 5000:
		await process_frame
		frames += 1
		worst_process = maxf(worst_process, Performance.get_monitor(Performance.TIME_PROCESS))
		if Time.get_ticks_msec() - started > 1000:
			cpu_samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
			tick_samples.append(root.get_node("GameManager").last_tick_usec / 1000.0)
	var seconds: float = (Time.get_ticks_msec() - started) / 1000.0
	var folder: String = OS.get_environment("DICE_TEST_OUTPUT")
	if not folder.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("stress-%d-dice.png" % count))
	print("STRESS: ", count, " auto dice, 8 helpers; frames/s=", snappedf(frames / seconds, 0.1), "; peak monitored process ms=", snappedf(worst_process * 1000, 0.01), "; rolls=", game.state.statistics.get("rolls", 0), "; memory MB=", snappedf(OS.get_static_memory_usage() / 1000000.0, 0.1))
	cpu_samples.sort()
	tick_samples.sort()
	if not cpu_samples.is_empty():
		print("PROFILE after 1s warmup: process median/p95 ms=", cpu_samples[int(cpu_samples.size() * 0.5)], "/", cpu_samples[int(cpu_samples.size() * 0.95)], "; gameplay tick median/p95 ms=", tick_samples[int(tick_samples.size() * 0.5)], "/", tick_samples[int(tick_samples.size() * 0.95)])
	quit()
