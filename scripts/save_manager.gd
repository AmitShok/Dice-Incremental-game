extends Node
var store: SaveStore
var elapsed: float = 0.0
var status: String = ""
var offline_amount: float = 0.0

func _ready() -> void:
	if GameManager.testing:
		set_process(false)
		return
	store = SaveStore.new(GameManager.registry)
	var state: GameState = store.load_state()
	if state == null and not store.protected and not FileAccess.file_exists(store.path) and FileAccess.file_exists("user://save.json"):
		var legacy := FileAccess.open("user://save.json", FileAccess.READ)
		if legacy != null:
			state = store.decode(legacy.get_as_text())
	if state != null:
		GameManager.session = GameSession.new(GameManager.registry, state)
		offline_amount = GameManager.session.offline(Time.get_unix_time_from_system() - state.last_saved) if state.last_saved > 0 else 0.0
	status = store.error_message
	get_tree().auto_accept_quit = false

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 30 and GameManager.session.pending.is_empty():
		elapsed = 0
		save_game()

func save_game() -> bool:
	if store == null:
		return false
	GameManager.session.settle()
	var success: bool = store.write(GameManager.session.state)
	status = "Saved" if success else store.error_message
	return success
