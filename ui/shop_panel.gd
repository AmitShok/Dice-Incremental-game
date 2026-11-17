class_name ShopPanel
extends VBoxContainer
## The right-hand shop, laid out like a compact item list: icon tabs at the top, cards that are
## bought by clicking them (icon, name, price, owned count), and an info box at the bottom that
## explains whatever card the pointer or finger is on. Hats and tables are picture tiles.
## Fate talents open as a tree over the table (TalentTree).

var session: GameSession
var page: String = "Dice"
## Purchase cards on the current page: {"button", "kind", "id", "price", "count"}.
var rows: Array[Dictionary] = []
## Picture tiles on the current page: {"button", "kind" ("hat"/"table"), "id"}.
var tiles: Array[Dictionary] = []
@onready var body: VBoxContainer = $Scroll/Body
@onready var scroll: ScrollContainer = $Scroll
@onready var page_title: Label = $Title
@onready var info_icon: TextureRect = $Info/Line/Icon
@onready var info_name: Label = $Info/Line/Text/Name
@onready var info_text: Label = $Info/Line/Text/Summary
var stats_label: Label
var chips_label: Label
var capsule_button: Button
var reveal: HBoxContainer
var on_notice: Callable
var on_prestige: Callable
var on_reset: Callable
var on_developer_tools: Callable
var on_fate: Callable = func(): pass
var on_settings_changed: Callable = func(): pass
var developer_tools_enabled: bool = false
## Upgrades with these stats appear on the Helpers page instead of Upgrades.
const HELPER_STATS: Array[String] = ["helper_speed", "helper_payout", "helper_smart", "helper_hands"]
const ITEM_SCENE: PackedScene = preload("res://scenes/ui/shop_item.tscn")
const MUTED := Color(0.74, 0.78, 0.72)
const GOLD := Color("#f4ce83")
const AFFORD := Color("#f3dfb4")
const SHORT := Color("#e0665a")
const TITLES: Dictionary = {"Dice": "DICE", "Upgrades": "UPGRADES", "Helpers": "HELPERS & HATS", "Tables": "TABLES",
	"Fate": "FATE", "Ledger": "LEDGER", "Settings": "SETTINGS"}
const HINTS: Dictionary = {
	"Dice": "Click a die to buy it. Drag dice on the table into the tray to sell them.",
	"Upgrades": "Upgrades help every die on the table.",
	"Helpers": "Helpers throw dice for you. Roll 1s for chips, open capsules for hats.",
	"Tables": "Each table bends one rule. Unlock more by playing.",
	"Fate": "Each Fate you hold makes every roll pay 1% more. Keep it, or spend it on permanent talents.",
	"Ledger": "Everything you have rolled so far.",
	"Settings": "Make yourself comfortable."}

func setup(game: GameSession) -> void:
	session = game
	var group := ButtonGroup.new()
	var icons: Dictionary = {"Dice": ShopIcons.die(session.registry.dice.get("d6", session.registry.dice.values()[0])),
		"Upgrades": ShopIcons.icon("up"), "Helpers": ShopIcons.icon("hire"), "Tables": ShopIcons.icon("table"),
		"Fate": ShopIcons.icon("prestige"), "Ledger": ShopIcons.icon("book"), "Settings": ShopIcons.icon("gear")}
	for container in [$Tabs, $Footer]:
		for button in container.get_children():
			# Icons draw at exactly 2x, the same pixel size as the rest of the art.
			ShopIcons.set_button_picture(button, icons.get(String(button.name)))
			button.toggle_mode = true
			button.button_group = group
			button.pressed.connect(func(): show_page(button.name))
	show_page("Dice")

# --- Building blocks ----------------------------------------------------------------

func label_text(text: String, font_size: int = 12, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = color
	return label

func section(text: String) -> void:
	var label := label_text(text.to_upper(), 12, GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(label)

## Shows an item's explanation in the info box (hover, focus or tap).
func show_info(icon: Texture2D, title: String, text: String) -> void:
	info_icon.texture = icon
	info_name.text = title
	info_text.text = text

func _hint() -> void:
	show_info(null, TITLES.get(page, page).capitalize(), HINTS.get(page, ""))

## Adds one click-to-buy card. `callback` returns true on success.
func item(icon: Texture2D, title: String, info: String, callback: Callable, kind: String, id: String) -> Dictionary:
	var button: Button = ITEM_SCENE.instantiate()
	body.add_child(button)
	button.get_node("Line/Icon").texture = icon
	button.get_node("Line/Text/Name").text = title
	var explain: Callable = func(): show_info(icon, title, info)
	button.mouse_entered.connect(explain)
	button.focus_entered.connect(explain)
	button.pressed.connect(func():
		explain.call()
		if callback.call():
			# Refresh prices/ownership without rebuilding cards or resetting scroll/focus.
			update_rows()
		else:
			on_notice.call("Not enough money yet, or this is still locked.")
	)
	var entry: Dictionary = {"button": button, "kind": kind, "id": id,
		"price": button.get_node("Line/Text/Price"), "count": button.get_node("Line/Count")}
	rows.append(entry)
	return entry

func tile(icon: Texture2D, text: String, info_title: String, info: String, size: Vector2, kind: String, id: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = size
# Small icons (hats, hat options) draw at exactly 2x; big thumbnails (tables) fill the tile.
	if icon != null and icon.get_width() <= 16:
		ShopIcons.set_button_picture(button, icon, 4.0 if text.is_empty() else 2.0)
	else:
		button.icon = icon
		button.expand_icon = true
	button.text = text
	button.toggle_mode = true
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override("font_size", 12)
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	var explain: Callable = func(): show_info(icon, info_title if not info_title.is_empty() else button.tooltip_text, info)
	button.mouse_entered.connect(explain)
	button.pressed.connect(func():
		explain.call()
		on_press.call()
		update_rows()
	)
	tiles.append({"button": button, "kind": kind, "id": id})
	return button

func grid(columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 5)
	g.add_theme_constant_override("v_separation", 5)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(g)
	return g

# --- Pages --------------------------------------------------------------------------

func show_page(which: String) -> void:
	page = which
	rows.clear()
	tiles.clear()
	stats_label = null
	chips_label = null
	capsule_button = null
	reveal = null
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	scroll.scroll_vertical = 0
	page_title.text = TITLES.get(which, which.to_upper())
	for container in [$Tabs, $Footer]:
		if container.has_node(which):
			container.get_node(which).set_pressed_no_signal(true)
	_hint()
	match page:
		"Dice": _dice_page()
		"Upgrades": _upgrades_page()
		"Helpers": _helpers_page()
		"Tables": _tables_page()
		"Fate": _fate_page()
		"Ledger":
			stats_label = label_text("", 12)
			body.add_child(stats_label)
		"Settings": _settings_page()
	update_rows()

func _dice_page() -> void:
	for id in session.registry.dice:
		var definition: DiceDefinition = session.registry.dice[id]
		item(ShopIcons.die(definition), definition.display_name, definition.summary + ". " + definition.description,
			func(): return session.progression.buy_die(id), "die", id)

func _upgrades_page() -> void:
	for id in session.registry.upgrades:
		var definition: UpgradeDefinition = session.registry.upgrades[id]
		if not definition.stat in HELPER_STATS:
			item(_upgrade_icon(definition), definition.display_name, definition.description,
				func(): return session.progression.buy_upgrade(id), "upgrade", id)

func _helpers_page() -> void:
	item(ShopIcons.icon("hire"), "Helper", "Walks to a ready die and throws it for you. Helpers are your only automation.",
		func(): return session.progression.hire_helper(), "helper", "")
	for id in session.registry.upgrades:
		var definition: UpgradeDefinition = session.registry.upgrades[id]
		if definition.stat in HELPER_STATS:
			item(_upgrade_icon(definition), definition.display_name, definition.description,
				func(): return session.progression.buy_upgrade(id), "upgrade", id)
	section("Hats")
	_capsule_card()
	var hats: GridContainer = grid(5)
	hats.add_child(tile(ShopIcons.icon("none"), "", "No hats", "Bare heads all round.", Vector2(54, 46), "hat", "", func(): session.progression.wear_hat("")))
	hats.add_child(tile(ShopIcons.icon("mix"), "", "Mix", "Every helper wears a different hat from your collection.", Vector2(54, 46), "hat", "mix", func(): session.progression.wear_hat("mix")))
	for id in Cosmetics.HATS:
		var info: Dictionary = Cosmetics.HATS[id]
		hats.add_child(tile(ShopIcons.hat(id), "", info.name, info.rarity.capitalize() + " hat. Tap to put it on every helper.", Vector2(54, 46), "hat", id, func(): session.progression.wear_hat(id)))

func _capsule_card() -> void:
	capsule_button = ITEM_SCENE.instantiate()
	body.add_child(capsule_button)
	capsule_button.get_node("Line/Icon").texture = ShopIcons.icon("capsule")
	capsule_button.get_node("Line/Text/Name").text = "Hat capsule"
	chips_label = capsule_button.get_node("Line/Text/Price")
	var info: String = "Every 1 you roll drops a chip. A capsule costs %d chips and holds a random hat. Duplicates give %d chips back." % [Cosmetics.CAPSULE_COST, Cosmetics.DUPLICATE_REFUND]
	var explain: Callable = func(): show_info(ShopIcons.icon("capsule"), "Hat capsule", info)
	capsule_button.mouse_entered.connect(explain)
	capsule_button.focus_entered.connect(explain)
	capsule_button.pressed.connect(func():
		explain.call()
		_pull_capsule()
	)
	reveal = HBoxContainer.new()
	reveal.visible = false
	reveal.alignment = BoxContainer.ALIGNMENT_CENTER
	reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prize := TextureRect.new()
	prize.name = "Prize"
	prize.custom_minimum_size = Vector2(64, 48)
	prize.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prize.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prize.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reveal.add_child(prize)
	var name_label := label_text("", 12)
	name_label.name = "Name"
	# A wrapping label inside a shrink-centred row gets zero width and wraps every letter.
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reveal.add_child(name_label)
	body.add_child(reveal)

func _pull_capsule() -> void:
	var before: Array = session.state.hats.duplicate()
	var hat: String = session.progression.pull_capsule()
	if hat.is_empty():
		on_notice.call("You need %d chips. Every 1 you roll drops one." % Cosmetics.CAPSULE_COST)
		return
	var info: Dictionary = Cosmetics.HATS[hat]
	reveal.get_node("Prize").texture = ShopIcons.hat(hat)
	var name_label: Label = reveal.get_node("Name")
	name_label.text = "%s!\n%s%s" % [info.name, info.rarity.capitalize(), "" if not before.has(hat) else " · duplicate, +%d chips" % Cosmetics.DUPLICATE_REFUND]
	name_label.modulate = ShopIcons.RARITY_COLORS[info.rarity]
	reveal.visible = true
	update_rows()
	# Wait one frame so the row has its real size before popping it from the centre.
	var shown: HBoxContainer = reveal
	await get_tree().process_frame
	if not is_instance_valid(shown):
		return
	shown.pivot_offset = shown.size * 0.5
	shown.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(shown, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _tables_page() -> void:
	var tables: GridContainer = grid(2)
	for id in TableCatalog.TABLES:
		var info: Dictionary = TableCatalog.TABLES[id]
		var texture: Texture2D = load("res://assets/exported/tables/%s.png" % id)
		tables.add_child(tile(texture, info.name, info.name, info.rule + "  Unlock: " + info.unlock, Vector2(150, 100), "table", id, func(): session.select_table(id)))

func _fate_page() -> void:
	var button: Button = ITEM_SCENE.instantiate()
	body.add_child(button)
	button.get_node("Line/Icon").texture = ShopIcons.icon("prestige")
	button.get_node("Line/Text/Name").text = "Begin again"
	button.pressed.connect(func(): on_prestige.call())
	button.mouse_entered.connect(func(): show_info(ShopIcons.icon("prestige"), "Begin again", "Trade this run for Fate. Each Fate you hold makes every roll pay 1% more. Dice, money, helpers and upgrades reset; talents stay."))
	rows.append({"button": button, "kind": "prestige", "id": "", "price": button.get_node("Line/Text/Price"), "count": button.get_node("Line/Count")})
	var tree: Button = ITEM_SCENE.instantiate()
	body.add_child(tree)
	tree.get_node("Line/Icon").texture = ShopIcons.icon("fortune")
	tree.get_node("Line/Text/Name").text = "Talent tree"
	tree.get_node("Line/Text/Price").text = "Spend Fate on permanent talents"
	tree.get_node("Line/Count").text = ""
	tree.pressed.connect(func(): on_fate.call())
	on_fate.call()

func _settings_page() -> void:
	var settings: VBoxContainer = preload("res://scenes/ui/settings_page.tscn").instantiate()
	body.add_child(settings)
	settings.get_node("DeveloperTools").visible = developer_tools_enabled
	settings.get_node("DeveloperTools").pressed.connect(func(): on_developer_tools.call())
	for key in ["sound", "music", "motion", "flashes", "numbers", "particles"]:
		var button: Button = settings.get_node(key)
		var setting_title: String = button.text
		button.text += " · ON" if session.state.settings[key] else " · OFF"
		button.pressed.connect(func():
			session.state.settings[key] = not session.state.settings[key]
			button.text = setting_title + (" · ON" if session.state.settings[key] else " · OFF")
			on_settings_changed.call()
		)
	var volume: HSlider = settings.get_node("Volume")
	volume.value = session.state.settings.volume
	volume.value_changed.connect(func(value: float):
		session.state.settings.volume = value
		on_settings_changed.call()
	)
	settings.get_node("Save").pressed.connect(func():
		SaveManager.save_game()
		on_notice.call(SaveManager.status)
	)
	settings.get_node("Reset").pressed.connect(func(): on_reset.call())

func _upgrade_icon(definition: UpgradeDefinition) -> Texture2D:
	var texture: Texture2D = ShopIcons.icon(definition.id)
	if texture == null and session.registry.dice.has(definition.target):
		texture = ShopIcons.die(session.registry.dice[definition.target])
	return texture

# --- Live state ---------------------------------------------------------------------

func update_rows() -> void:
	var state: GameState = session.state
	var shown_locked: Dictionary = {}
	for entry in rows:
		var button: Button = entry.button
		var price: Label = entry.price
		var count: Label = entry.count
		var id: String = entry.id
		var cost: float = 0.0
		var locked: bool = false
		var owned: bool = false
		var lock_note: String = ""
		match entry.kind:
			"die":
				var definition: DiceDefinition = session.registry.dice[id]
				cost = session.economy.die_price(id)
				locked = state.run_earned < definition.unlock_earned
				lock_note = "Earn $" + NumberFormat.compact(definition.unlock_earned) + " to unlock"
				if state.dice.size() >= GameState.MAX_DICE:
					locked = true
					lock_note = "Table full"
				count.text = "×%d" % int(state.counts.get(id, 0))
			"upgrade":
				var definition: UpgradeDefinition = session.registry.upgrades[id]
				var level: int = int(state.upgrades.get(id, 0))
				cost = session.economy.upgrade_price(definition)
				owned = level >= definition.max_level
				locked = state.run_earned < definition.unlock_earned
				lock_note = "Earn $" + NumberFormat.compact(definition.unlock_earned) + " to unlock"
				count.text = "%d/%d" % [level, definition.max_level]
			"helper":
				cost = session.progression.helper_price()
				owned = state.helpers >= GameState.MAX_HELPERS
				locked = state.run_earned < 150
				lock_note = "Earn $150 to unlock"
				count.text = "%d/%d" % [state.helpers, GameState.MAX_HELPERS]
			"prestige":
				var reward: int = session.progression.fate_reward()
				button.disabled = reward <= 0
				price.text = ("+%d Fate now" % reward) if reward > 0 else "Earn $%s more" % NumberFormat.compact(maxf(0.0, session.progression.prestige_threshold() - state.run_earned))
				price.modulate = GOLD if reward > 0 else MUTED
				count.text = ""
				continue
		# Show every unlocked card, but only the next locked one in each group as a teaser.
		var hide: bool = locked and shown_locked.has(entry.kind)
		if locked:
			shown_locked[entry.kind] = true
		button.visible = not hide
		button.modulate = Color(1, 1, 1, 0.6) if locked else Color.WHITE
		var affordable: bool = state.money >= cost
		# Unaffordable cards stay lit with a red price; only locked or maxed cards are disabled.
		button.disabled = owned or locked
		if owned:
			price.text = "Maxed" if entry.kind != "helper" else "Crew full"
			price.modulate = MUTED
		elif locked:
			price.text = lock_note
			price.modulate = MUTED
		else:
			price.text = "$" + NumberFormat.compact(cost)
			price.modulate = AFFORD if affordable else SHORT
	_update_tiles()
	_update_ledger()

func _update_tiles() -> void:
	var state: GameState = session.state
	for entry in tiles:
		var button: Button = entry.button
		var id: String = entry.id
		match entry.kind:
			"hat":
				var owned: bool = id.is_empty() or id == "mix" or state.hats.has(id)
				button.disabled = not owned or (id == "mix" and state.hats.size() < 2)
				button.set_pressed_no_signal(state.crew_hat == id)
				# Unfound hats show as dark silhouettes, so the collection is visible at a glance.
				var picture: Node = button.get_node_or_null("Picture")
				if picture != null:
					picture.modulate = Color(0, 0, 0, 0.55) if button.disabled else Color.WHITE
				if Cosmetics.HATS.has(id):
					button.tooltip_text = Cosmetics.HATS[id].name if owned else "Not found yet"
			"table":
				var unlocked: bool = state.tables.has(id)
				button.disabled = not unlocked
				button.set_pressed_no_signal(state.table_id == id)
				button.text = TableCatalog.TABLES[id].name if unlocked else "Locked"
				button.add_theme_color_override("icon_disabled_color", Color(0.25, 0.25, 0.28, 1))
	if chips_label != null:
		chips_label.text = "%d chips · costs %d" % [state.chips, Cosmetics.CAPSULE_COST]
		chips_label.modulate = AFFORD if state.chips >= Cosmetics.CAPSULE_COST else SHORT
		capsule_button.get_node("Line/Count").text = "%d/%d" % [state.hats.size(), Cosmetics.HATS.size()]
		capsule_button.disabled = state.chips < Cosmetics.CAPSULE_COST

func _update_ledger() -> void:
	if stats_label == null:
		return
	var state: GameState = session.state
	var text: String = ""
	text += "Fate held: %d\nFate earned in total: %d\nEach Fate you hold makes every roll pay 1%% more.\n\n" % [state.prestige_points, state.prestige_total]
	for pair in [["rolls", "Dice rolled"], ["earned", "Lifetime earnings"], ["best_payout", "Largest payout"], ["maximums", "Maximum rolls"], ["minimums", "Minimum rolls"], ["combos", "Combinations"], ["criticals", "Critical rolls"], ["helpers_hired", "Helpers hired"], ["prestiges", "Fresh starts"], ["offline_earned", "Offline earnings"], ["best_streak", "Best hot streak"], ["arcs", "Dice sparked"], ["blasts", "Blasts"], ["gilded", "Dice gilded"], ["dice_sold", "Dice sold"], ["chips", "Chips found"], ["capsules", "Capsules opened"]]:
		text += "%s: %s\n" % [pair[1], NumberFormat.compact(float(state.statistics.get(pair[0], 0)))]
	text += "\nPlaytime: %.1f minutes\n\nMILESTONES\n" % (float(state.statistics.get("playtime", 0)) / 60.0)
	for achievement in state.achievements:
		text += "• " + achievement + "\n"
	stats_label.text = text
