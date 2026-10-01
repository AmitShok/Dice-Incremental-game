class_name SaveStore
extends RefCounted

const VERSION: int = 1
var path: String
var error_message: String = ""
var recovered: bool = false
var protected: bool = false
var registry: ContentRegistry

func _init(content: ContentRegistry, save_path: String = "user://progress.json") -> void:
	registry = content
	path = save_path

func decode(text: String) -> GameState:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return null
	if not parsed.has("save_version") and parsed.has("currency"):
		if not GameState.valid_number(parsed.currency):
			return null
		var legacy := GameState.new()
		legacy.money = float(parsed.currency)
		legacy.add_die("d6", Vector2(395, 310))
		return legacy
	if not GameState.valid_number(parsed.get("save_version"), 1) or floor(float(parsed.save_version)) != float(parsed.save_version):
		return null
	if float(parsed.save_version) > VERSION:
		protected = true
		error_message = "This save belongs to a newer version. Saving is disabled to protect it."
		return null
	if int(parsed.save_version) != VERSION or not parsed.get("state") is Dictionary:
		return null
	return GameState.restore(parsed.state, registry)

func load_state() -> GameState:
	error_message = ""
	recovered = false
	protected = false
	if not FileAccess.file_exists(path):
		return null
	var primary := FileAccess.open(path, FileAccess.READ)
	if primary != null:
		var result: GameState = decode(primary.get_as_text())
		if result != null:
			return result
	if protected:
		return null
	if FileAccess.file_exists(path + ".bak"):
		var backup := FileAccess.open(path + ".bak", FileAccess.READ)
		if backup != null:
			var result: GameState = decode(backup.get_as_text())
			if result != null:
				recovered = true
				error_message = "Recovered your previous save from backup."
				return result
	protected = true
	error_message = "Save could not be read. Original files are preserved; saving is disabled."
	return null

func write(state: GameState) -> bool:
	if protected:
		return false
	state.last_saved = Time.get_unix_time_from_system()
	var payload: Dictionary = {"save_version": VERSION, "state": state.snapshot()}
	var serialized: String = JSON.stringify(payload)
	if decode(serialized) == null:
		error_message = "Save validation failed; previous save preserved."
		return false
	var temp := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if temp == null:
		error_message = "Unable to write save file."
		return false
	temp.store_string(serialized)
	temp.flush()
	if temp.get_error() != OK:
		temp.close()
		error_message = "Save write was incomplete; previous save preserved."
		return false
	temp.close()
	var candidate := FileAccess.open(path + ".tmp", FileAccess.READ)
	if candidate == null or decode(candidate.get_as_text()) == null:
		error_message = "Written save could not be verified; previous save preserved."
		return false
	candidate.close()
	# Promote only a validated file. Never replace a known-good backup with corrupt primary data.
	if FileAccess.file_exists(path):
		var original := FileAccess.open(path, FileAccess.READ)
		var original_text: String = original.get_as_text() if original != null else ""
		if original != null:
			original.close()
		var previous: GameState = decode(original_text)
		if protected:
			return false
		if previous != null:
			var copy_error: Error = DirAccess.copy_absolute(path, path + ".bak")
			if copy_error != OK:
				error_message = "Backup failed; save was not replaced."
				return false
	var replace_error: Error = DirAccess.rename_absolute(path + ".tmp", path)
	if replace_error != OK:
		error_message = "Could not replace save; temporary file retained."
		return false
	error_message = ""
	return true
