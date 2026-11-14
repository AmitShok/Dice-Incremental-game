class_name DiceVisual
extends Control

signal selected(id: int)
signal moved(id: int, position: Vector2)
## Emitted while dragging so the table can highlight the sell tray.
signal drag_moved(id: int, center: Vector2)
## Emitted on release after a drag; the table decides between moving and selling.
signal dropped(id: int, center: Vector2)

## Dragging may leave the felt to reach the sell tray below it.
const DRAG_MIN := Vector2(40, 140)
const DRAG_MAX := Vector2(780, 592)
var die: DiceInstance
var definition: DiceDefinition
@onready var sprite: Sprite2D = $Face
@onready var shadow: Sprite2D = $Shadow
@onready var marker: Label = $Marker
@onready var game_manager: Node = get_node("/root/GameManager")
@export var tumble_frames: int = 32
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
var drag_threshold: float = 6.0
var drag_started: bool = false
var original_position: Vector2
var age: float = 0
var rolling: bool = false

func _ready() -> void:
	set_process(false)
	# The "D6" tag sits on the felt, so it uses the outlined pixel font.
	marker.add_theme_font_override("font", preload("res://assets/fonts/d_infinity_pixel_outline.fnt"))

func set_density(count: int) -> void:
	# Dice art is 32 px drawn at 2x (Face scale 2), so a factor of 1 puts one art pixel on two screen
	# pixels, the same grid as the room. Crowded tables step down to 1.5x and then 1x.
	var factor: float = 1.0 if count <= 16 else (0.75 if count <= 30 else 0.5)
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
			drag_started = false
			# Touch-emulated mouse events use device -1; measure tolerance in screen pixels.
			drag_threshold = 12.0 / maxf(0.1, get_viewport().get_final_transform().x.length()) if event.device == -1 else 6.0
			press_position = event.global_position
			original_position = position
		elif not event.pressed and dragging:
			dragging = false
			z_index = 0
			if event.canceled:
				position = original_position
			elif not drag_started:
				selected.emit(die.id)
			else:
				dropped.emit(die.id, position + Vector2(32, 32) * scale)
			accept_event()
	elif event is InputEventMouseMotion and dragging and not die.busy:
		if not drag_started and press_position.distance_to(event.global_position) < drag_threshold:
			return
		drag_started = true
		# Float above the HUD (sell tray, labels) while held, so the die never hides under them.
		z_index = 50
		var center: Vector2 = original_position + event.global_position - press_position + Vector2(32, 32) * scale
		position = center.clamp(DRAG_MIN, DRAG_MAX) - Vector2(32, 32) * scale
		drag_moved.emit(die.id, center.clamp(DRAG_MIN, DRAG_MAX))

func start(outcome: Dictionary, settings: Dictionary) -> void:
	rolling = true
	dragging = false
	z_index = 0
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
		# Finish at the shared resting orientation instead of snapping from a random pose.
		var end_frame: float = ceilf((tumble_offset + tumble_frames * tumble_cycles) / tumble_frames) * tumble_frames
		sprite.frame = int(lerpf(tumble_offset, end_frame, turnover)) % tumble_frames
	else:
		if sprite.texture != definition.texture:
			sprite.texture = definition.texture
			sprite.hframes = definition.sides
		sprite.frame = result_face
	shadow.position = Vector2(32, 46)
	# The shadow art is 22x6 at 2x; it shrinks a little while the die is airborne.
	shadow.scale = Vector2.ONE * (2.0 - lift * 0.016)
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
	shadow.position = Vector2(32, 53)
	shadow.scale = Vector2(2, 2)
	shadow.visible = not dense
	marker.text = "CRIT!" if outcome.critical else ("MAX!" if outcome.face == outcome.sides else "D%d" % definition.sides)
	tooltip_text = "%s\n%s\nLast roll: %d → $%s%s\nClick to roll · drag to arrange" % [definition.display_name, definition.description, outcome.face, NumberFormat.compact(outcome.payout), " (includes bonuses)" if not is_equal_approx(outcome.payout, float(outcome.face)) else ""]
	marker.modulate = Color("#f4ce83") if outcome.face == outcome.sides else Color("#b9c5ae")

## Returns the visual to the die's authoritative position (after a move or a refused sale).
func snap() -> void:
	dragging = false
	if not rolling:
		position = die.position - Vector2(32, 32) * scale
	update_gild()

## Gilded dice glow warm gold until their next roll consumes the bonus.
func update_gild() -> void:
	if die == null or rolling:
		return
	sprite.self_modulate = Color(1.25, 1.08, 0.55) if die.gilded else Color.WHITE
	if die.gilded:
		marker.text = "GILDED"
		marker.modulate = Color("#ffd86b")
