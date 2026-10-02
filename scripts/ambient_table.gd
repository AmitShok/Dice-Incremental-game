extends Node2D

@export var flame_fps: float = 7.0
@export var steam_fps: float = 6.0
@export var plant_fps: float = 3.0
@onready var manager: Node = get_node("/root/GameManager")
@onready var left_flame: Sprite2D = $LeftFlame
@onready var right_flame: Sprite2D = $RightFlame
@onready var steam: Sprite2D = $Steam
@onready var plant: Sprite2D = $Plant
var elapsed: float = 0.0

func _process(delta: float) -> void:
	var motion: bool = manager.session.state.settings.get("motion", true)
	steam.visible = motion
	if not motion:
		left_flame.frame = 0
		right_flame.frame = 0
		plant.frame = 0
		return
	if manager.session.paused:
		return
	elapsed += delta
	_set_frame(left_flame, int(elapsed * flame_fps) % left_flame.hframes)
	_set_frame(right_flame, (int(elapsed * flame_fps * 0.93) + 3) % right_flame.hframes)
	_set_frame(steam, int(elapsed * steam_fps) % steam.hframes)
	_set_frame(plant, int(elapsed * plant_fps) % plant.hframes)

func _set_frame(sprite: Sprite2D, next_frame: int) -> void:
	if sprite.frame != next_frame:
		sprite.frame = next_frame
