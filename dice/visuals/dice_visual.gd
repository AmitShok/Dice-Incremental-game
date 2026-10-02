class_name DiceVisual
extends Control

signal selected(id: int)
signal moved(id: int, position: Vector2)
var die: DiceInstance
var definition: DiceDefinition
@onready var sprite: Sprite2D = $Face
@onready var shadow: Sprite2D = $Shadow
@onready var marker: Label = $Marker
@onready var game_manager: Node = get_node("/root/GameManager")
@export var tumble_frames: int = 24
@export var tumble_cycles: float = 1.5
@export var bounce_height: float = 30.0
var roll_duration: float = 1.0
var roll_origin: Vector2
var roll_destination: Vector2
var result_face: int = 0
var tumble_offset: int = 0
var motion_enabled: bool = true
var dense: bool = false
var dragging: bool = false
var press_position: Vector2
var original_position: Vector2
var age: float = 0
var rolling: bool = false

func _ready() -> void:
	set_process(false)

func set_density(count: int) -> void:
	var factor: float = 0.5 if count > 30 else 0.65
	dense = count > 30
	scale = Vector2.ONE * factor
	# Faces already carry a contact shadow; dense tables do not need a second shadow or tiny labels.
	shadow.visible = not dense
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
	position = die.position - Vector2(32, 32) * scale
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
		var center: Vector2 = original_position + event.global_position - press_position + Vector2(32, 32) * scale
		position = center.clamp(Vector2(65, 150), Vector2(725, 500)) - Vector2(32, 32) * scale

func start(outcome: Dictionary, settings: Dictionary) -> void:
	rolling = true
	dragging = false
	age = 0.0
	roll_duration = maxf(0.01, outcome.duration)
	roll_origin = die.position
	roll_destination = outcome.landing_position
	result_face = outcome.face - 1
	tumble_offset = int(outcome.roll_id * 7) % tumble_frames
	motion_enabled = settings.motion
	position = die.position - Vector2(32, 32) * scale
	marker.text = "..."
	shadow.visible = not dense
	sprite.modulate = Color.WHITE
	set_process(true)
	_update_roll_pose(0.0)

func _process(delta: float) -> void:
	if game_manager.session.paused:
		return
	age += delta
	_update_roll_pose(clampf(age / roll_duration, 0.0, 1.0))

func _update_roll_pose(t: float) -> void:
	if not motion_enabled:
		sprite.texture = definition.texture
		sprite.hframes = definition.sides
		sprite.frame = result_face if t >= 0.86 else die.face - 1
		return
	# Travel loses speed while the body tumbles around two axes in the Aseprite atlas.
	var distance_progress: float = 1.0 - pow(1.0 - t, 2.0)
	position = roll_origin.lerp(roll_destination, distance_progress) - Vector2(32,32) * scale
	var phase: float
	var height: float
	if t < 0.52:
		phase = t / 0.52
		height = bounce_height
	elif t < 0.86:
		phase = (t - 0.52) / 0.34
		height = bounce_height * 0.38
	else:
		phase = (t - 0.86) / 0.14
		height = bounce_height * 0.08
	var lift: float = sin(phase * PI) * height
	var impact: float = pow(absf(2.0 * phase - 1.0), 12.0) * (1.0 - t)
	sprite.position = Vector2(32, 28 - lift)
	sprite.scale = Vector2(2.0 + impact * 0.3, 2.0 - impact * 0.36)
	sprite.rotation = sin(t * TAU * 3.0) * 0.10 * (1.0 - t)
	if t < 0.86 and definition.rolling_texture != null:
		if sprite.texture != definition.rolling_texture:
			sprite.texture = definition.rolling_texture
			sprite.hframes = tumble_frames
		var turnover: float = 1.0 - pow(1.0 - t / 0.86, 1.45)
		sprite.frame = (tumble_offset + int(turnover * tumble_frames * tumble_cycles)) % tumble_frames
	else:
		if sprite.texture != definition.texture:
			sprite.texture = definition.texture
			sprite.hframes = definition.sides
		sprite.frame = result_face
	shadow.position = Vector2(32, 46)
	shadow.scale = Vector2.ONE * (1.35 - lift * 0.012)
	shadow.modulate.a = 0.85 - lift * 0.013

func land(outcome: Dictionary, settings: Dictionary) -> void:
	rolling = false
	set_process(false)
	position = die.position - Vector2(32, 32) * scale
	sprite.texture = definition.texture
	sprite.hframes = definition.sides
	sprite.frame = outcome.face - 1
	sprite.rotation = 0
	sprite.position = Vector2(32, 28)
	sprite.scale = Vector2(2, 2)
	sprite.modulate = Color.WHITE
	shadow.modulate.a = 1.0
	shadow.position = Vector2(32, 55)
	shadow.scale = Vector2(1.5, 1.5)
	shadow.visible = not dense
	marker.text = "CRIT!" if outcome.critical else ("MAX!" if outcome.face == outcome.sides else "D%d" % definition.sides)
	marker.modulate = Color("#f4ce83") if outcome.face == outcome.sides else Color("#b9c5ae")
