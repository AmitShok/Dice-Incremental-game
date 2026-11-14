class_name ShopPanel
extends VBoxContainer

var session: GameSession
var page: String = "Dice"
var rows: Array[Dictionary] = []
@onready var body: VBoxContainer = $Scroll/Body
@onready var scroll: ScrollContainer = $Scroll
var stats_label: Label
var on_notice: Callable
var on_prestige: Callable
var on_reset: Callable
var on_developer_tools: Callable
var on_settings_changed: Callable = func(): pass
var developer_tools_enabled: bool = false
## Upgrades with these stats appear on the Helpers page instead of Upgrades.
const HELPER_STATS: Array[String] = ["helper_speed", "helper_payout", "helper_smart", "helper_hands"]

func setup(game: GameSession) -> void:
	session = game
	for group in [$Tabs, $Footer]:
		for button in group.get_children():
			button.pressed.connect(func(): show_page(button.name))
	show_page("Dice")

func label_text(text: String, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func card(title: String, description: String, die_id: String = "") -> VBoxContainer:
	var panel: PanelContainer = preload("res://scenes/ui/shop_card.tscn").instantiate()
	body.add_child(panel)
	var box: VBoxContainer = panel.get_node("Content")
	box.get_node("Header/Title").text = title
	if session.registry.dice.has(die_id):
		var definition: DiceDefinition = session.registry.dice[die_id]
		var icon: TextureRect = box.get_node("Header/DieIcon")
		var face := AtlasTexture.new()
		face.atlas = definition.texture
		face.region = Rect2((definition.sides - 1) * 32, 0, 32, 32)
		face.filter_clip = true
		icon.texture = face
		icon.tooltip_text = definition.display_name
		icon.show()
	box.get_node("Description").text = description
	return box

func _requirement_text(definition: UpgradeDefinition) -> String:
	if definition.prerequisite.is_empty() or not session.registry.talents.has(definition.prerequisite):
		return ""
	return " Requires %s." % session.registry.talents[definition.prerequisite].display_name

func purchase_button(box: VBoxContainer, callback: Callable, kind: String, id: String) -> void:
	var button: Button = box.get_node("Purchase")
	button.pressed.connect(func():
		if callback.call():
			# Refresh prices/ownership without rebuilding cards or resetting scroll/focus.
			update_rows()
		else:
			on_notice.call("Not enough currency, or this purchase is locked.")
	)
	rows.append({"button": button, "kind": kind, "id": id})

func show_page(which: String) -> void:
	page = which
	rows.clear()
	stats_label = null
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	scroll.scroll_vertical = 0
	match page:
		"Dice":
			body.add_child(label_text("A little luck goes a long way.", 13))
			for id in session.registry.dice:
				var definition: DiceDefinition = session.registry.dice[id]
				var box: VBoxContainer = card(definition.display_name, definition.description, id)
				purchase_button(box, func(): return session.progression.buy_die(id), "die", id)
		"Upgrades":
			for id in session.registry.upgrades:
				var definition: UpgradeDefinition = session.registry.upgrades[id]
				if definition.stat in HELPER_STATS:
					continue
				var box: VBoxContainer = card(definition.display_name, definition.description, definition.target)
				purchase_button(box, func(): return session.progression.buy_upgrade(id), "upgrade", id)
		"Helpers":
			var box: VBoxContainer = card("Hire a croupier", "Moss and friends walk to ready dice and throw them for you. Helpers are your table's only automation: make them faster, stronger and smarter below.")
			purchase_button(box, func(): return session.progression.hire_helper(), "helper", "")
			body.add_child(label_text("Training", 19))
			for id in session.registry.upgrades:
				var definition: UpgradeDefinition = session.registry.upgrades[id]
				if not definition.stat in HELPER_STATS:
					continue
				var training: VBoxContainer = card(definition.display_name, definition.description)
				purchase_button(training, func(): return session.progression.buy_upgrade(id), "upgrade", id)
		"Tables":
			body.add_child(label_text("Choose your table. Each one bends the rules; switch any time.", 13))
			for id in TableCatalog.TABLES:
				var info: Dictionary = TableCatalog.TABLES[id]
				var table_box: VBoxContainer = card(info.name, info.rule + "\nUnlock: " + info.unlock)
				var table_button: Button = table_box.get_node("Purchase")
				table_button.pressed.connect(func():
					session.select_table(id)
					update_rows()
				)
				rows.append({"button": table_button, "kind": "table", "id": id})
			body.add_child(label_text("Capsule machine", 19))
			var capsule_box: VBoxContainer = card("Hat capsule", "Every natural 1 drops a chip. Spend %d chips for a random hat for your helpers. Duplicates return %d chips." % [Cosmetics.CAPSULE_COST, Cosmetics.DUPLICATE_REFUND])
			var capsule_button: Button = capsule_box.get_node("Purchase")
			capsule_button.pressed.connect(func():
				var hat: String = session.progression.pull_capsule()
				if hat.is_empty():
					on_notice.call("Not enough chips. Roll more ones!")
				else:
					on_notice.call("Capsule: %s (%s)!" % [Cosmetics.HATS[hat].name, Cosmetics.HATS[hat].rarity])
					show_page("Tables")
			)
			rows.append({"button": capsule_button, "kind": "capsule", "id": ""})
			body.add_child(label_text("Wardrobe", 19))
			for id in ["", "mix"] + session.state.hats:
				var title: String = "No hats" if id == "" else ("Mix them up" if id == "mix" else Cosmetics.HATS[id].name)
				var detail: String = "Bare heads all round." if id == "" else ("Each helper wears a different hat from your collection." if id == "mix" else Cosmetics.HATS[id].rarity.capitalize() + " hat.")
				var hat_box: VBoxContainer = card(title, detail)
				var hat_button: Button = hat_box.get_node("Purchase")
				hat_button.pressed.connect(func():
					session.progression.wear_hat(id)
					update_rows()
				)
				rows.append({"button": hat_button, "kind": "hat", "id": id})
		"Fate":
			var box: VBoxContainer = card("Begin again, luckier", "At $%s earned this run, trade the table for Fate. The more you earn, the more Fate you take. Each Fate earned adds +10%% income permanently. Dice, money, helpers and ordinary upgrades reset. Talents, settings and lifetime statistics stay." % NumberFormat.compact(ProgressionService.PRESTIGE_THRESHOLD))
			var button: Button = box.get_node("Purchase")
			button.pressed.connect(func(): on_prestige.call())
			var hint: Label = label_text("", 12)
			hint.modulate = Color(1, 1, 1, 0.7)
			box.add_child(hint)
			rows.append({"button": button, "kind": "prestige", "id": "", "hint": hint})
			body.add_child(label_text("Permanent talents", 19))
			for id in session.registry.talents:
				var definition: UpgradeDefinition = session.registry.talents[id]
				var talent_box: VBoxContainer = card(definition.display_name, definition.description + _requirement_text(definition), definition.target)
				purchase_button(talent_box, func(): return session.progression.buy_upgrade(id, true), "talent", id)
		"Ledger":
			stats_label = label_text("", 15)
			body.add_child(stats_label)
		"Settings":
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

	update_rows()

func update_rows() -> void:
	var state: GameState = session.state
	for row in rows:
		var button: Button = row.button
		var id: String = row.id
		var cost: float = 0.0
		var locked: bool = false
		var owned: bool = false
		var note: String = ""
		match row.kind:
			"die":
				var definition: DiceDefinition = session.registry.dice[id]
				cost = session.economy.die_price(id)
				locked = state.run_earned < definition.unlock_earned or state.dice.size() >= GameState.MAX_DICE
				note = "Own %d · " % int(state.counts.get(id, 0))
				if state.dice.size() >= GameState.MAX_DICE:
					note = "Table full · 100 dice"
				if state.run_earned < definition.unlock_earned:
					note = "Earn $" + NumberFormat.compact(definition.unlock_earned) + " to unlock"
			"upgrade", "talent":
				var permanent: bool = row.kind == "talent"
				var definition: UpgradeDefinition = session.registry.talents[id] if permanent else session.registry.upgrades[id]
				var levels: Dictionary = state.talents if permanent else state.upgrades
				var level: int = int(levels.get(id, 0))
				cost = session.economy.upgrade_price(definition)
				owned = level >= definition.max_level
				locked = (not permanent and state.run_earned < definition.unlock_earned) or (not definition.prerequisite.is_empty() and int(levels.get(definition.prerequisite, 0)) == 0)
				note = "%d/%d · " % [level, definition.max_level]
				if locked:
					note = "Requires " + session.registry.talents[definition.prerequisite].display_name if permanent else "Earn $" + NumberFormat.compact(definition.unlock_earned) + " to unlock"
			"helper":
				cost = session.progression.helper_price()
				owned = state.helpers >= GameState.MAX_HELPERS
				locked = state.run_earned < 150
				note = "%d/%d hired · " % [state.helpers, GameState.MAX_HELPERS]
				if locked:
					note = "Earn $150 to unlock"
			"table":
				var unlocked: bool = state.tables.has(id)
				button.disabled = not unlocked or state.table_id == id
				button.text = "In use" if state.table_id == id else ("Use this table" if unlocked else "Locked")
				continue
			"capsule":
				button.disabled = state.chips < Cosmetics.CAPSULE_COST
				button.text = "Pull · %d chips  (you have %d)" % [Cosmetics.CAPSULE_COST, state.chips]
				continue
			"hat":
				button.disabled = state.crew_hat == id
				button.text = "Wearing" if state.crew_hat == id else "Wear"
				continue
			"prestige":
				var reward: int = session.progression.fate_reward()
				button.text = "Begin again · +%d Fate" % reward if reward > 0 else "$%s / $%s earned" % [NumberFormat.compact(state.run_earned), NumberFormat.compact(ProgressionService.PRESTIGE_THRESHOLD)]
				button.tooltip_text = "Next Fate at $%s earned this run" % NumberFormat.compact(session.progression.next_fate_at()) if reward > 0 else ""
				if reward > 0 and row.has("hint"):
					row.hint.text = "+1 more Fate at $%s earned this run." % NumberFormat.compact(session.progression.next_fate_at())
				button.disabled = reward <= 0
				continue
		var available: float = state.prestige_points if row.kind == "talent" else state.money
		button.disabled = owned or locked or available < cost
		button.text = "Owned" if owned else note + ("" if locked else ("Buy · %s Fate" % NumberFormat.compact(cost) if row.kind == "talent" else "$" + NumberFormat.compact(cost)))
	if stats_label != null:
		var text: String = "THE LEDGER\n\n"
		for pair in [["rolls", "Dice rolled"], ["earned", "Lifetime earnings"], ["best_payout", "Largest payout"], ["maximums", "Maximum rolls"], ["minimums", "Minimum rolls"], ["combos", "Combinations"], ["criticals", "Critical rolls"], ["helpers_hired", "Helpers hired"], ["prestiges", "Fresh starts"], ["offline_earned", "Offline earnings"], ["best_streak", "Best hot streak"], ["arcs", "Dice sparked"], ["blasts", "Blasts"], ["gilded", "Dice gilded"], ["dice_sold", "Dice sold"], ["chips", "Chips found"], ["capsules", "Capsules opened"]]:
			text += "%s: %s\n" % [pair[1], NumberFormat.compact(float(state.statistics.get(pair[0], 0)))]
		text += "\nPlaytime: %.1f minutes\n\nMILESTONES\n" % (float(state.statistics.get("playtime", 0)) / 60.0)
		for achievement in state.achievements:
			text += "• " + achievement + "\n"
		stats_label.text = text
