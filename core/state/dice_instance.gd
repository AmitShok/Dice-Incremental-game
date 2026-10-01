class_name DiceInstance
extends RefCounted

var id: int = 0
var definition_id: String = ""
var position: Vector2 = Vector2.ZERO
var face: int = 1
var cooldown: float = 0.0
var automatic_clock: float = 0.0
var busy: bool = false

func snapshot() -> Dictionary:
	return {"id": id, "definition_id": definition_id, "x": position.x, "y": position.y, "face": face, "automatic_clock": automatic_clock}
