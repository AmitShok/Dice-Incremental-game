extends SceneTree
# Controlled rendering probes; always run with -- --test to avoid player saves.

func _initialize() -> void:
	call_deferred("run")

func percentile(samples: Array[float], fraction: float) -> float:
	return samples[mini(samples.size() - 1, int(samples.size() * fraction))] if not samples.is_empty() else 0.0

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		push_error("Benchmark requires --test")
		quit(1)
		return
	var mode: String = "full"
	var vsync_off: bool = false
	var duration: float = 6.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
		if argument == "--vsync=off":
			vsync_off = true
		if argument.begins_with("--seconds="):
			duration = clampf(argument.trim_prefix("--seconds=").to_float(), 2, 60)
	if mode not in ["blank", "full", "silent", "static", "hidden"]:
		push_error("Unknown benchmark mode: " + mode)
		quit(1)
		return
	if vsync_off and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var manager: Node = root.get_node("GameManager")
	var game: GameSession = manager.session
	if mode == "blank":
		manager.set_process(false)
	else:
		game.state.dice.clear()
		game.state.counts.clear()
		for index in 100:
			game.state.add_die("d6", Vector2(85 + index % 11 * 61, 170 + int(index / 11) * 34))
		game.state.automatic.d6 = true
		game.state.helpers = 8
		game.roller.rng.seed = 38
		if mode == "silent":
			game.state.settings.sound = false
		if mode == "static":
			game.paused = true
		var main: Control = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		if mode == "hidden":
			main.hide()
	await create_timer(2.0).timeout
	var frames: Array[float] = []
	var ticks: Array[float] = []
	var start: int = Time.get_ticks_usec()
	var previous: int = start
	var starting_rolls: int = int(game.state.statistics.get("rolls", 0))
	var starting_money: float = game.state.money
	var memory_start: int = OS.get_static_memory_usage()
	var slow_frames: int = 0
	while Time.get_ticks_usec() - start < duration * 1000000:
		await process_frame
		var now: int = Time.get_ticks_usec()
		frames.append((now - previous) / 1000.0)
		if now - previous > 33333:
			slow_frames += 1
		ticks.append(manager.last_tick_usec / 1000.0 if mode != "blank" else 0.0)
		previous = now
	var elapsed: float = (previous - start) / 1000000.0
	frames.sort()
	ticks.sort()
	var report: Dictionary = {
		"mode": mode, "display": DisplayServer.get_name(), "vsync_requested_off": vsync_off,
		"vsync_actual": DisplayServer.window_get_vsync_mode() if DisplayServer.get_name() != "headless" else -1,
		"seconds": elapsed, "frames": frames.size(), "fps": frames.size() / elapsed,
		"frame_ms_median": percentile(frames, 0.5), "frame_ms_p95": percentile(frames, 0.95),
		"frame_ms_p99": percentile(frames, 0.99), "tick_ms_median": percentile(ticks, 0.5),
		"tick_ms_p95": percentile(ticks, 0.95),
		"frames_over_33ms": slow_frames, "frame_ms_max": frames.back(),
		"resolved_rolls": int(game.state.statistics.get("rolls", 0)) - starting_rolls,
		"money_earned": game.state.money - starting_money,
		"memory_start_mb": memory_start / 1000000.0,
		"memory_end_mb": OS.get_static_memory_usage() / 1000000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render_objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)}
	print("BENCHMARK ", JSON.stringify(report))
	if mode in ["full", "silent", "hidden"] and (report.resolved_rolls <= 0 or report.money_earned <= 0):
		push_error("Active benchmark completed without resolved rolls and payouts")
		quit(1)
		return
	quit()
