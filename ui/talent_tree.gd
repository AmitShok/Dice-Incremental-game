class_name TalentTree
extends PanelContainer
## Fate talents as a full-screen map over the table (scenes/ui/talent_tree.tscn).
##
## The scene holds the real structure: the header (Close, title, held Fate, Begin again), the map
## (Map/Links, a TalentLinks control holding one TalentNode instance per talent, named by id, at
## its position) and the info box. Open talent_tree.tscn in Godot to see or rearrange the tree;
## links redraw live in the editor. Rebuild it from the talents' tree_position values with
## tools/build_talent_tree_scene.gd (this replaces hand edits).
##
## The whole map fits on screen at once: no scroll area, no clipping, no panning. A clipped,
## scrolled map drew nothing at all on iPhone browsers (WebKit's WebGL).
##
## Each Fate held makes every roll pay 1% more, so the header and info box always show what a
## purchase costs in that bonus: holding versus spending is the decision this screen is about.

const NODE_SCENE: PackedScene = preload("res://scenes/ui/talent_node.tscn")
## Spacing used to place a talent the scene has no node for (from its .tres tree_position).
const CELL := Vector2(92, 66)
const MARGIN := Vector2(8, 4)
const OPEN_GRACE_MSEC: int = 400
const GOLD := Color("#f4ce83")
const LILAC := Color("#c5b4df")
const DIM := Color(0.42, 0.42, 0.5)

var session: GameSession
var on_prestige: Callable = func(): pass
var on_notice: Callable = func(_message: String): pass
## Talent id -> TalentNode.
var nodes: Dictionary = {}
var shown_id: String = ""
## When the tree last opened; taps are ignored for OPEN_GRACE_MSEC afterwards (see settled()).
var opened_msec: int = -100000

@onready var close_button: Button = $Column/Header/Close
@onready var held_label: Label = $Column/Header/Middle/Held
@onready var total_label: Label = $Column/Header/Middle/Total
@onready var begin_button: Button = $Column/Header/Begin
@onready var canvas: TalentLinks = $Column/Map/Links
@onready var info_icon: TextureRect = $Column/Info/Line/Icon
@onready var info_name: Label = $Column/Info/Line/Text/Name
@onready var info_text: Label = $Column/Info/Line/Text/Body
@onready var info_trade: Label = $Column/Info/Line/Text/Trade

func setup(game: GameSession) -> void:
	session = game
	# Close sits at the left end: the right end of the header lies exactly under the shop's
	# Fate tab, so a second tap there (or a phone's follow-up click) would close the tree at once.
	close_button.pressed.connect(func():
		if settled():
			hide()
	)
	begin_button.pressed.connect(func():
		if settled():
			on_prestige.call()
	)
	_collect_nodes()
	hide()

## True once the tree has been open long enough that a tap is meant for it, not a leftover
## of the tap that opened it (a double tap, or a touch browser's follow-up mouse click).
func settled() -> bool:
	return Time.get_ticks_msec() - opened_msec >= OPEN_GRACE_MSEC

## Uses the TalentNode instances placed in the scene. Content stays the authority: icons and
## prerequisites come from the talents' .tres files, nodes for unknown talents are hidden, and a
## talent the scene has no node for gets one at its tree_position.
func _collect_nodes() -> void:
	for child in canvas.get_children():
		var node := child as TalentNode
		if node == null:
			continue
		if session.registry.talents.has(String(node.name)):
			nodes[String(node.name)] = node
		else:
			node.hide()
	var low := Vector2i(1000, 1000)
	for id in session.registry.talents:
		var cell: Vector2i = session.registry.talents[id].tree_position
		low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
	for id in session.registry.talents:
		var definition: UpgradeDefinition = session.registry.talents[id]
		if not nodes.has(id):
			var node: TalentNode = NODE_SCENE.instantiate()
			node.name = id
			node.position = MARGIN + Vector2(definition.tree_position - low) * CELL
			canvas.add_child(node)
			nodes[id] = node
		var talent: TalentNode = nodes[id]
		talent.talent_id = id
		talent.prerequisite = definition.prerequisite
		talent.icon_texture = icon_for(definition)
		talent.mouse_entered.connect(func(): explain(id))
		talent.pressed.connect(func(): _buy(id))

func icon_for(definition: UpgradeDefinition) -> Texture2D:
	if not definition.target.is_empty() and session.registry.dice.has(definition.target):
		return ShopIcons.die(session.registry.dice[definition.target])
	return ShopIcons.icon(definition.icon if not definition.icon.is_empty() else definition.id)

func _buy(id: String) -> void:
	if not settled():
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
	info_icon.texture = icon_for(definition)
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

func open() -> void:
	opened_msec = Time.get_ticks_msec()
	refresh()
	explain("fortune")
	shown_id = ""
	info_name.text = "Tap or click a talent to buy a rank."
	info_text.text = "Talents are permanent. Each Fate you hold makes every roll pay 1% more, so spending Fate trades that bonus for a talent."
	info_trade.text = ""
	show()

func refresh() -> void:
	var state: GameState = session.state
	held_label.text = "%d Fate held" % state.prestige_points
	total_label.text = "Each Fate you hold makes every roll pay 1%% more.  Earned in total: %d" % state.prestige_total
	var reward: int = session.progression.fate_reward()
	begin_button.disabled = reward <= 0
	begin_button.text = "Begin again · +%d Fate" % reward if reward > 0 else "Fate at $%s" % NumberFormat.compact(session.progression.prestige_threshold())
	var owned: Dictionary = {}
	for id in nodes:
		var definition: UpgradeDefinition = session.registry.talents[id]
		var button: TalentNode = nodes[id]
		var level: int = _level(id)
		if level > 0:
			owned[id] = true
		var maxed: bool = level >= definition.max_level
		var locked: bool = _needs_missing(definition)
		button.set_rank(str(level) if definition.max_level > 99 else "%d/%d" % [level, definition.max_level])
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
	canvas.owned = owned
	if not shown_id.is_empty():
		explain(shown_id)
	canvas.queue_redraw()
