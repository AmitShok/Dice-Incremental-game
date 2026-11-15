extends Node
var registry: ContentRegistry
var session: GameSession
var testing: bool = false
var last_tick_usec: int = 0

func _ready() -> void:
	testing = OS.get_cmdline_user_args().has("--test")
	if testing:
		# Test windows may be hidden, but their audio otherwise reaches the speakers.
		# Mute the whole test process, including future music/UI audio sources.
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	registry = ContentRegistry.new()
	if not registry.errors.is_empty():
		push_error("Invalid content: " + str(registry.errors))
	session = GameSession.new(registry)
	set_process(true)

func _process(delta: float) -> void:
	var start: int = Time.get_ticks_usec()
	session.tick(delta)
	last_tick_usec = Time.get_ticks_usec() - start

func roll_all_dice() -> void:
	session.roll_table()

func _notification(what: int) -> void:
	if testing:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game()
		get_tree().quit()
	# Losing focus or being paused by the OS (alt-tab, a phone backgrounding the browser) is often
	# the last chance to save before the game is closed.
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game()
