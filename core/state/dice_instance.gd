class_name DiceInstance
extends RefCounted

var id: int = 0
var definition_id: String = ""
var position: Vector2 = Vector2.ZERO
var face: int = 1
var cooldown: float = 0.0
# Retained for save compatibility; automatic rolling was replaced by helpers.
var automatic_clock: float = 0.0
var busy: bool = false
# Set by a Gild die's landing; the next roll of this die pays the gilded bonus once.
var gilded: bool = false

func snapshot() -> Dictionary:
	return {"id": id, "definition_id": definition_id, "x": position.x, "y": position.y, "face": face, "automatic_clock": automatic_clock, "gilded": gilded}
