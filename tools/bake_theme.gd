extends SceneTree
func _initialize() -> void:
	var result: Error = ResourceSaver.save(GameTheme.build(), "res://ui/game_theme.tres")
	quit(0 if result == OK else 1)
