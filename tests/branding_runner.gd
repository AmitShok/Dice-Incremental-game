extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		quit(1)
		return
	var correct: bool = ProjectSettings.get_setting("application/config/name") == "D- infinity"
	var icon: Texture2D = load(ProjectSettings.get_setting("application/config/icon"))
	correct = correct and icon != null and icon.get_size() == Vector2(256,256)
	correct = correct and FileAccess.file_exists(ProjectSettings.get_setting("application/config/windows_native_icon"))
	if OS.get_name() == "Windows":
		var expected: String = OS.get_environment("APPDATA").replace("\\", "/").path_join("Godot/app_userdata/DiceIncremental")
		correct = correct and OS.get_user_data_dir().replace("\\", "/") == expected
	var hud: Control = load("res://scenes/ui/hud.tscn").instantiate()
	correct = correct and hud.get_node("Title").text == "D- infinity"
	hud.free()
	print("BRANDING: ", "passed; title, icon and existing save directory verified" if correct else "FAILED")
	quit(0 if correct else 1)
