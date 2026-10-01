class_name DiceVisual
extends Control

signal selected(id: int)
signal moved(id: int, position: Vector2)
var die: DiceInstance
var definition: DiceDefinition
@onready var sprite: Sprite2D = $Face
@onready var shadow: Sprite2D = $Shadow
@onready var marker: Label = $Marker
var animation: Tween
var dragging: bool = false
var press_position: Vector2
var original_position: Vector2
var age: float = 0
var rolling: bool = false

func _ready() -> void:
	set_process(false)

func set_density(count: int) -> void:
	var factor: float = 0.5 if count > 30 else 1.0
	scale = Vector2.ONE * factor
	# Faces already carry a contact shadow; dense tables do not need a second shadow or tiny labels.
	shadow.visible = count <= 30
	marker.visible = count <= 30
	if not dragging and not rolling:
		position = die.position - Vector2(32, 32) * scale

func setup(instance: DiceInstance, content: DiceDefinition) -> void:
	die = instance
	definition = content
	tooltip_text = "%s\n%s\nClick to roll · drag to arrange" % [definition.display_name, definition.description]
	sprite.texture = definition.texture
	sprite.hframes = definition.sides
	sprite.frame = die.face - 1
	marker.text = "D%d" % definition.sides
	position = die.position - Vector2(32, 32)
	mouse_entered.connect(func(): if not rolling: sprite.modulate = Color(1.15, 1.12, 1.05))
	mouse_exited.connect(func(): sprite.modulate = Color.WHITE)
	set_process(false)

func _gui_input(event: InputEvent) -> void:
	if die == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not die.busy:
			dragging = true
			press_position = event.global_position
			original_position = position
		elif not event.pressed and dragging:
			dragging = false
			if press_position.distance_to(event.global_position) < 6:
				selected.emit(die.id)
			else:
				moved.emit(die.id, position + Vector2(32, 32) * scale)
			accept_event()
	elif event is InputEventMouseMotion and dragging and not die.busy:
		position = (original_position + event.global_position - press_position).clamp(Vector2(33, 118), Vector2(693, 468))

func start(outcome: Dictionary, settings: Dictionary) -> void:
	rolling = true
	dragging = false
	age = 0.0
	if animation != null:
		animation.kill()
	position = die.position - Vector2(32, 32) * scale
	marker.text = "..."
	set_process(true)
	var duration: float = outcome.duration
	animation = create_tween()
	if settings.motion and scale.x < 1:
		animation.tween_property(sprite, "position:y", 12.0, duration * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		animation.tween_property(sprite, "position:y", 28.0, duration * 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	elif settings.motion:
		animation.tween_property(sprite, "scale", Vector2(2.2, 1.6), duration * 0.12)
		animation.tween_property(sprite, "position", Vector2(32 + sin(outcome.roll_id * 2.4) * 22, -15), duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		animation.parallel().tween_property(sprite, "scale", Vector2(1.9, 2.2), duration * 0.3)
		animation.parallel().tween_property(sprite, "rotation", TAU * (1 if outcome.roll_id % 2 else -1), duration * 0.6)
		animation.tween_property(sprite, "position", Vector2(32, 28), duration * 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		animation.tween_interval(duration * 0.8)

func _process(delta: float) -> void:
	age += delta
	var next_frame: int = int(age * 19 + die.id * 3) % definition.sides
	if sprite.frame != next_frame:
		sprite.frame = next_frame
	if shadow.visible:
		shadow.modulate.a = 0.6 if sprite.position.y < 0 else 1.0

func land(outcome: Dictionary, settings: Dictionary) -> void:
	rolling = false
	set_process(false)
	if animation != null:
		animation.kill()
	sprite.frame = outcome.face - 1
	sprite.rotation = 0
	sprite.position = Vector2(32, 28)
	sprite.scale = Vector2(2, 2)
	sprite.modulate = Color.WHITE
	shadow.modulate.a = 1.0
	marker.text = "CRIT!" if outcome.critical else ("MAX!" if outcome.face == outcome.sides else "D%d" % definition.sides)
	marker.modulate = Color("#f4ce83") if outcome.face == outcome.sides else Color("#b9c5ae")
	if settings.motion and scale.x >= 1:
		var bounce := create_tween()
		sprite.scale = Vector2(2.25, 1.7)
		bounce.tween_property(sprite, "scale", Vector2(2, 2), 0.2).set_trans(Tween.TRANS_BACK)
