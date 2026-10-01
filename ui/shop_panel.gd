class_name ShopPanel
extends VBoxContainer

var session: GameSession
var page: String = "Dice"
var rows: Array[Dictionary] = []
var body := VBoxContainer.new()
var scroll := ScrollContainer.new()
var stats_label: Label
var on_notice: Callable
var on_prestige: Callable
var on_reset: Callable

func setup(game: GameSession) -> void:
	session = game
	position = Vector2(792, 94)
	size = Vector2(310, 486)
	var tabs := HBoxContainer.new()
	for title in ["Dice", "Upgrades", "Helpers", "Fate"]:
		var button := Button.new()
		button.text = title
		button.add_theme_font_size_override("font_size", 13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): show_page(title))
		tabs.add_child(button)
	add_child(tabs)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var footer := HBoxContainer.new()
	for title in ["Ledger", "Settings"]:
		var button := Button.new()
		button.text = title
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): show_page(title))
		footer.add_child(button)
	add_child(footer)
	show_page("Dice")

func label_text(text: String, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func card(title: String, description: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	body.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(label_text(title, 17))
	var text := label_text(description, 13)
	text.modulate = Color("#b2bfaf")
	box.add_child(text)
	return box

func purchase_button(box: VBoxContainer, callback: Callable, kind: String, id: String) -> void:
	var button := Button.new()
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(func():
		if callback.call():
			show_page(page)
		else:
			on_notice.call("Not enough currency, or this purchase is locked.")
	)
	box.add_child(button)
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
				var box: VBoxContainer = card(definition.display_name, definition.description)
				purchase_button(box, func(): return session.progression.buy_die(id), "die", id)
		"Upgrades":
			for id in session.registry.upgrades:
				var definition: UpgradeDefinition = session.registry.upgrades[id]
				var box: VBoxContainer = card(definition.display_name, definition.description)
				purchase_button(box, func(): return session.progression.buy_upgrade(id), "upgrade", id)
		"Helpers":
			var box: VBoxContainer = card("Meet Moss", "A tiny croupier with very big ambitions. Walks to ready dice and rolls them for you.")
			purchase_button(box, func(): return session.progression.hire_helper(), "helper", "")
			body.add_child(label_text("Enchanted dice", 19))
			body.add_child(label_text("Per-family auto-rolls. Helpers focus on the dice that still need a hand.", 13))
			for id in session.state.counts:
				var definition: DiceDefinition = session.registry.dice[id]
				var auto_box: VBoxContainer = card(definition.display_name, "Every owned die in this family rolls automatically.")
				purchase_button(auto_box, func(): return session.progression.buy_automatic(id), "automatic", id)
		"Fate":
			var box: VBoxContainer = card("Begin again, luckier", "At $%s earned this run, trade the table for Fate. Each Fate earned adds +10%% income permanently. Dice, money, helpers and ordinary upgrades reset. Talents, settings and lifetime statistics stay." % NumberFormat.compact(ProgressionService.PRESTIGE_THRESHOLD))
			var button := Button.new()
			button.pressed.connect(func(): on_prestige.call())
			box.add_child(button)
			rows.append({"button": button, "kind": "prestige", "id": ""})
			body.add_child(label_text("Permanent talents", 19))
			for id in session.registry.talents:
				var definition: UpgradeDefinition = session.registry.talents[id]
				var talent_box: VBoxContainer = card(definition.display_name, definition.description + (" Requires Fortune favors you." if not definition.prerequisite.is_empty() else ""))
				purchase_button(talent_box, func(): return session.progression.buy_upgrade(id, true), "talent", id)
		"Ledger":
			stats_label = label_text("", 15)
			body.add_child(stats_label)
		"Settings":
			body.add_child(label_text("Make yourself comfortable.", 19))
			for pair in [["sound", "Sound effects"], ["motion", "Motion & bounce"], ["flashes", "Counter flashes"], ["numbers", "Floating payouts"], ["particles", "Celebration sparks"]]:
				var key: String = pair[0]
				var button := Button.new()
				button.text = pair[1] + (" · ON" if session.state.settings[key] else " · OFF")
				button.pressed.connect(func():
					session.state.settings[key] = not session.state.settings[key]
					show_page("Settings")
				)
				body.add_child(button)
			body.add_child(label_text("Volume", 14))
			var volume := HSlider.new()
			volume.min_value = 0.0
			volume.max_value = 1.0
			volume.step = 0.05
			volume.value = session.state.settings.volume
			volume.value_changed.connect(func(value: float): session.state.settings.volume = value)
			body.add_child(volume)
			var save := Button.new()
			save.text = "Save now"
			save.pressed.connect(func():
				SaveManager.save_game()
				on_notice.call(SaveManager.status)
			)
			body.add_child(save)
			body.add_child(label_text("Autosaves every 30 seconds and on exit. Offline earnings: 50% of estimated production, up to four hours.", 13))
			var reset := Button.new()
			reset.text = "Reset all progress..."
			reset.pressed.connect(func(): on_reset.call())
			body.add_child(reset)
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
					note = "Requires " + definition.prerequisite.capitalize() if permanent else "Earn $" + NumberFormat.compact(definition.unlock_earned) + " to unlock"
			"helper":
				cost = session.progression.helper_price()
				owned = state.helpers >= 8
				locked = state.run_earned < 150
				note = "%d hired · " % state.helpers
				if locked:
					note = "Earn $150 to unlock"
			"automatic":
				cost = session.registry.dice[id].auto_cost
				owned = bool(state.automatic.get(id, false))
			"prestige":
				var reward: int = session.progression.fate_reward()
				button.text = "Begin again · +%d Fate" % reward if reward > 0 else "$%s / $%s earned" % [NumberFormat.compact(state.run_earned), NumberFormat.compact(ProgressionService.PRESTIGE_THRESHOLD)]
				button.disabled = reward <= 0
				continue
		var available: float = state.prestige_points if row.kind == "talent" else state.money
		button.disabled = owned or locked or available < cost
		button.text = "Owned" if owned else note + ("" if locked else ("Buy · %s Fate" % NumberFormat.compact(cost) if row.kind == "talent" else "$" + NumberFormat.compact(cost)))
	if stats_label != null:
		var text: String = "THE LEDGER\n\n"
		for pair in [["rolls", "Dice rolled"], ["earned", "Lifetime earnings"], ["best_payout", "Largest payout"], ["maximums", "Maximum rolls"], ["minimums", "Minimum rolls"], ["combos", "Combinations"], ["criticals", "Critical rolls"], ["helpers_hired", "Helpers hired"], ["prestiges", "Fresh starts"], ["offline_earned", "Offline earnings"]]:
			text += "%s: %s\n" % [pair[1], NumberFormat.compact(float(state.statistics.get(pair[0], 0)))]
		text += "\nPlaytime: %.1f minutes\n\nMILESTONES\n" % (float(state.statistics.get("playtime", 0)) / 60.0)
		for achievement in state.achievements:
			text += "• " + achievement + "\n"
		stats_label.text = text
