class_name TalentTree
extends PanelContainer
## Fate talents as a big map over the table. Each talent sits on its own cell (tree_position in
## its .tres) with Fortune in the middle; lines join each talent to the one it needs. Drag the
## map (or scroll) to look around, point at a node to read it, click to buy a rank.
##
## Each Fate held makes every roll pay 1% more, so the header and info box always show what a
## purchase costs in that bonus: holding versus spending is the decision this screen is about.

var session: GameSession
var on_prestige: Callable = func(): pass
var on_notice: Callable = func(_message: String): pass
var nodes: Dictionary = {}
var scroll: ScrollContainer
var canvas: Control
var held_label: Label
var total_label: Label
var begin_button: Button
var info_icon: TextureRect
var info_name: Label
var info_text: Label
var info_trade: Label
var dragging: bool = false
var dragged: float = 0.0
var shown_id: String = ""
const NODE_SIZE := Vector2(58, 58)
const CELL := Vector2(92, 84)
const MARGIN := Vector2(40, 30)
const GOLD := Color("#f4ce83")
const LILAC := Color("#c5b4df")
const DIM := Color(0.42, 0.42, 0.5)

func setup(game: GameSession) -> void:
	session = game
	position = Vector2(16, 84)
	custom_minimum_size = Vector2(1088, 540)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 30
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(_header())
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.draw.connect(_draw_links)
	scroll.add_child(canvas)
	column.add_child(_info_box())
	_build_nodes()
	hide()

func _header() -> HBoxContainer:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "FATE TALENTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", GOLD)
	top.add_child(title)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 0)
	top.add_child(middle)
	held_label = Label.new()
	held_label.name = "Held"
	held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	held_label.add_theme_font_size_override("font_size", 17)
	held_label.add_theme_color_override("font_color", LILAC)
	middle.add_child(held_label)
	total_label = Label.new()
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 12)
	total_label.modulate = Color(1, 1, 1, 0.75)
	middle.add_child(total_label)
	begin_button = Button.new()
	begin_button.custom_minimum_size = Vector2(200, 40)
	begin_button.pressed.connect(func(): on_prestige.call())
	top.add_child(begin_button)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(70, 40)
	close.pressed.connect(hide)
	top.add_child(close)
	return top

func _info_box() -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(0, 76)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	box.add_child(line)
	info_icon = TextureRect.new()
	info_icon.custom_minimum_size = Vector2(40, 40)
	info_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.add_child(info_icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	line.add_child(text)
	info_name = Label.new()
	info_name.add_theme_color_override("font_color", GOLD)
	info_name.add_theme_font_size_override("font_size", 15)
	text.add_child(info_name)
	info_text = Label.new()
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.add_theme_font_size_override("font_size", 13)
	text.add_child(info_text)
	info_trade = Label.new()
	info_trade.add_theme_font_size_override("font_size", 12)
	info_trade.add_theme_color_override("font_color", LILAC)
	text.add_child(info_trade)
	return box

## Cells come from each talent's tree_position; the map is sized to fit them all.
func _build_nodes() -> void:
	var low := Vector2i(1000, 1000)
	var high := Vector2i(-1000, -1000)
	for id in session.registry.talents:
		var cell: Vector2i = session.registry.talents[id].tree_position
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
		high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
	for id in session.registry.talents:
		var cell: Vector2i = session.registry.talents[id].tree_position - low
		nodes[id] = _node_button(id, MARGIN + Vector2(cell) * CELL)
	canvas.custom_minimum_size = MARGIN * 2 + Vector2(high - low) * CELL + NODE_SIZE

func _icon_for(definition: UpgradeDefinition) -> Texture2D:
	if not definition.target.is_empty() and session.registry.dice.has(definition.target):
		return ShopIcons.die(session.registry.dice[definition.target])
	return ShopIcons.icon(definition.icon if not definition.icon.is_empty() else definition.id)

func _node_button(id: String, at: Vector2) -> Button:
	var button := Button.new()
	button.name = id
	button.position = at
	button.size = NODE_SIZE
	button.custom_minimum_size = NODE_SIZE
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	# Icon drawn at 2× (32 px) above the rank, so the picture carries the meaning.
	var picture := TextureRect.new()
	picture.name = "Icon"
	picture.texture = _icon_for(session.registry.talents[id])
	picture.position = Vector2((NODE_SIZE.x - 32) * 0.5, 5)
	picture.size = Vector2(32, 32)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(picture)
	var rank := Label.new()
	rank.name = "Rank"
	rank.position = Vector2(0, 38)
	rank.size = Vector2(NODE_SIZE.x, 16)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 11)
	rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(rank)
	button.mouse_entered.connect(func(): explain(id))
	button.pressed.connect(func(): _buy(id))
	canvas.add_child(button)
	return button

func _buy(id: String) -> void:
	# A drag that started on a node pans the map instead of buying.
	if dragged > 8.0:
		refresh()
		return
	if not session.progression.buy_upgrade(id, true):
		var definition: UpgradeDefinition = session.registry.talents[id]
		if _needs_missing(definition):
			on_notice.call("Buy %s first." % session.registry.talents[definition.prerequisite].display_name)
		elif _level(id) < definition.max_level:
			on_notice.call("Not enough Fate yet.")
	refresh()
	explain(id)

func _level(id: String) -> int:
	return int(session.state.talents.get(id, 0))

func _needs_missing(definition: UpgradeDefinition) -> bool:
	return not definition.prerequisite.is_empty() and _level(definition.prerequisite) == 0

func _price(definition: UpgradeDefinition) -> int:
	return int(session.economy.upgrade_price(definition))

## Fills the info box: what the talent does, its rank and price, and the held-Fate trade-off.
func explain(id: String) -> void:
	shown_id = id
	var definition: UpgradeDefinition = session.registry.talents[id]
	var level: int = _level(id)
	var maxed: bool = level >= definition.max_level
	var ranks: String = "rank %d" % level if definition.max_level > 99 else "%d/%d" % [level, definition.max_level]
	info_icon.texture = _icon_for(definition)
	info_name.text = "%s   %s   %s" % [definition.display_name, ranks, "MAXED" if maxed else "%s Fate" % NumberFormat.compact(_price(definition))]
	info_text.text = definition.description
	if _needs_missing(definition):
		info_trade.text = "Needs %s first." % session.registry.talents[definition.prerequisite].display_name
	elif maxed:
		info_trade.text = ""
	else:
		var held: int = session.state.prestige_points
		var after: int = held - _price(definition)
		info_trade.text = ("Costs %d Fate: your rolls would pay %d%% less until you earn it back." % [held - after, held - after]) if after >= 0 else "You need %d more Fate." % -after

func _draw_links() -> void:
	for id in nodes:
		var definition: UpgradeDefinition = session.registry.talents[id]
		if definition.prerequisite.is_empty() or not nodes.has(definition.prerequisite):
			continue
		var from: Vector2 = nodes[definition.prerequisite].position + NODE_SIZE * 0.5
		var to: Vector2 = nodes[id].position + NODE_SIZE * 0.5
		var owned: bool = _level(definition.prerequisite) > 0
		canvas.draw_line(from, to, Color(0, 0, 0, 0.45), 6.0)
		canvas.draw_line(from, to, GOLD if owned else Color(0.36, 0.34, 0.42), 3.0)

## Drags anywhere on the map pan it, even when they start on a node.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and scroll.get_global_rect().has_point(event.position):
			dragging = true
			dragged = 0.0
		elif not event.pressed:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		_pan(event.relative)

func _pan(relative: Vector2) -> void:
	dragged += relative.length()
	if dragged > 8.0:
		scroll.scroll_horizontal -= int(relative.x)
		scroll.scroll_vertical -= int(relative.y)

func open() -> void:
	refresh()
	explain("fortune")
	shown_id = ""
	info_name.text = "Click a talent to buy a rank. Drag to look around."
	info_text.text = "Talents are permanent. Each Fate you hold makes every roll pay 1% more, so spending Fate trades that bonus for a talent."
	info_trade.text = ""
	show()
	# Centre the map on Fortune once the scroll area has its size.
	await get_tree().process_frame
	if nodes.has("fortune"):
		var centre: Vector2 = nodes.fortune.position + NODE_SIZE * 0.5 - scroll.size * 0.5
		scroll.scroll_horizontal = int(maxf(0.0, centre.x))
		scroll.scroll_vertical = int(maxf(0.0, centre.y))

func refresh() -> void:
	var state: GameState = session.state
	held_label.text = "%d Fate held" % state.prestige_points
	total_label.text = "Each Fate you hold makes every roll pay 1%% more.  Earned in total: %d" % state.prestige_total
	var reward: int = session.progression.fate_reward()
	begin_button.disabled = reward <= 0
	begin_button.text = "Begin again · +%d Fate" % reward if reward > 0 else "Fate at $%s" % NumberFormat.compact(ProgressionService.PRESTIGE_THRESHOLD)
	for id in nodes:
		var definition: UpgradeDefinition = session.registry.talents[id]
		var button: Button = nodes[id]
		var level: int = _level(id)
		var maxed: bool = level >= definition.max_level
		var locked: bool = _needs_missing(definition)
		button.get_node("Rank").text = str(level) if definition.max_level > 99 else "%d/%d" % [level, definition.max_level]
		button.set_pressed_no_signal(maxed)
		button.disabled = locked
		var affordable: bool = state.prestige_points >= _price(definition)
		if locked:
			button.modulate = DIM
		elif maxed:
			button.modulate = Color(1, 0.95, 0.75)
		elif affordable:
			button.modulate = Color.WHITE
		else:
			button.modulate = Color(0.72, 0.72, 0.78)
		button.tooltip_text = definition.display_name
	if not shown_id.is_empty():
		explain(shown_id)
	canvas.queue_redraw()
