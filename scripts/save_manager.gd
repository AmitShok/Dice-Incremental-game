extends Node
## Saves and loads progress (user://progress.json, with a .bak backup).
##
## On the Web, user:// lives in the browser's IndexedDB, which Godot syncs asynchronously after
## each write, and the browser never sends a close request. So on the Web the game also:
##   - autosaves every few seconds instead of every 30,
##   - saves the moment the page is hidden or closed (tab switch, tab or browser closed, phone
##     screen locked), from the browser's visibilitychange and pagehide events,
##   - mirrors every save to localStorage, which is written synchronously and survives the tab
##     closing immediately; on load the newer of the two copies wins.
var store: SaveStore
var elapsed: float = 0.0
var status: String = ""
var offline_amount: float = 0.0

const AUTOSAVE_SECONDS: float = 30.0
const WEB_AUTOSAVE_SECONDS: float = 5.0
## Unique per game: itch.io serves many games from the same browser origin.
const WEB_MIRROR_KEY: String = "d-infinity/progress.json"

var web: bool = false
var _page_hidden_callback: JavaScriptObject
var _page_hide_callback: JavaScriptObject

func _ready() -> void:
	if GameManager.testing:
		set_process(false)
		return
	web = OS.has_feature("web")
	store = SaveStore.new(GameManager.registry)
	var state: GameState = store.load_state()
	if state == null and not store.protected and not FileAccess.file_exists(store.path) and FileAccess.file_exists("user://save.json"):
		var legacy := FileAccess.open("user://save.json", FileAccess.READ)
		if legacy != null:
			state = store.decode(legacy.get_as_text())
	if web and not store.protected:
		state = SaveStore.newest(state, _read_web_mirror())
	if state != null:
		GameManager.session = GameSession.new(GameManager.registry, state)
		offline_amount = GameManager.session.offline(Time.get_unix_time_from_system() - state.last_saved) if state.last_saved > 0 else 0.0
	status = store.error_message
	get_tree().auto_accept_quit = false
	if web:
		_listen_for_page_hide()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= (WEB_AUTOSAVE_SECONDS if web else AUTOSAVE_SECONDS) and GameManager.session.pending.is_empty():
		elapsed = 0
		save_game()

func save_game() -> bool:
	if store == null:
		return false
	GameManager.session.settle()
	var success: bool = store.write(GameManager.session.state)
	status = "Saved" if success else store.error_message
	if success and web:
		_write_web_mirror(store.last_serialized)
	return success

# --- Web storage ----------------------------------------------------------------------------

func _storage_helpers() -> JavaScriptObject:
	# localStorage can throw (private browsing, storage blocked in an iframe); never let that
	# break saving to user://.
	JavaScriptBridge.eval("""
		window.__dInfinityStorage = window.__dInfinityStorage || {
			save: function (key, text) { try { localStorage.setItem(key, text); return true; } catch (e) { return false; } },
			load: function (key) { try { return localStorage.getItem(key) || ""; } catch (e) { return ""; } }
		};
	""", true)
	return JavaScriptBridge.get_interface("__dInfinityStorage")

func _write_web_mirror(text: String) -> void:
	if text.is_empty():
		return
	var storage: JavaScriptObject = _storage_helpers()
	if storage != null:
		storage.save(WEB_MIRROR_KEY, text)

func _read_web_mirror() -> GameState:
	var storage: JavaScriptObject = _storage_helpers()
	if storage == null:
		return null
	var text: Variant = storage.load(WEB_MIRROR_KEY)
	if not text is String or String(text).is_empty():
		return null
	var state: GameState = store.decode(text)
	# A mirror written by a newer version protects itself the same way the file does.
	if store.protected:
		store.protected = false
		return null
	return state

func _listen_for_page_hide() -> void:
	_page_hidden_callback = JavaScriptBridge.create_callback(_on_visibility_change)
	_page_hide_callback = JavaScriptBridge.create_callback(_on_page_hide)
	var document: JavaScriptObject = JavaScriptBridge.get_interface("document")
	var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if document != null:
		document.addEventListener("visibilitychange", _page_hidden_callback)
	if window != null:
		window.addEventListener("pagehide", _page_hide_callback)

func _on_visibility_change(_args: Array) -> void:
	var document: JavaScriptObject = JavaScriptBridge.get_interface("document")
	if document != null and str(document.visibilityState) == "hidden":
		save_game()

func _on_page_hide(_args: Array) -> void:
	save_game()
