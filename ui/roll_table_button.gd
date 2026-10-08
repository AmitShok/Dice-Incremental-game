extends Button

@onready var manager: Node = get_node("/root/GameManager")
@onready var fill: ProgressBar = $CooldownFill
@onready var caption: Label = $Caption

func _ready() -> void:
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	var remaining: float = manager.session.state.table_roll_remaining
	disabled = remaining > 0.0 or manager.session.paused
	fill.value = GameState.TABLE_ROLL_COOLDOWN - remaining
	if remaining > 0.0:
		var seconds: int = ceili(remaining)
		caption.text = "ROLL THE TABLE  ·  %d:%02d" % [int(seconds / 60), seconds % 60]
	else:
		caption.text = "ROLL THE TABLE   [SPACE]"
	tooltip_text = "Ready in %d seconds" % ceili(remaining) if remaining > 0 else "Roll all ready dice · 60-second cooldown"
