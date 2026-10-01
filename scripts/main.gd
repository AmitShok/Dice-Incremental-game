extends Control

var session: GameSession
var table := Node2D.new()
var visuals: Dictionary = {}
var workers: Array[Sprite2D] = []
var wallet: Label
var income: Label
var fate: Label
var hint: Label
var toast: Label
var combo: Label
var shop: ShopPanel
var feedback: FeedbackManager
var audio: AudioService
var elapsed: float = 0.0
var toast_time: float = 0.0
var combo_time: float = 0.0
var debug_panel: PanelContainer
var confirm := ConfirmationDialog.new()
var hud_dirty: bool = false
var wallet_tween: Tween

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	session = GameManager.session
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = GameTheme.build()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var room := Sprite2D.new()
	room.texture = preload("res://assets/exported/environment/room.png")
	room.centered = false
	room.scale = Vector2(2, 2)
	add_child(room)
	add_child(table)
	_label("DICE / INCREMENTAL", Vector2(32, 12), 26, Color("#f4deaf"))
	_label("A SMALL TABLE.  IMPOSSIBLE POSSIBILITIES.", Vector2(33, 49), 11, Color("#b29979"))
	wallet = _label("$0", Vector2(454, 9), 29, Color("#f6d68f"))
	income = _label("Your first throw awaits", Vector2(455, 50), 12, Color("#b0b9aa"))
	fate = _label("FATE  0", Vector2(797, 17), 25, Color("#c5b4df"))
	_label("THE HOUSE OF POSSIBILITY", Vector2(798, 54), 11, Color("#aa9d90"))
	hint = _label("", Vector2(90, 96), 14, Color("#f1d6a4"))
	combo = _label("", Vector2(150, 430), 26, Color("#f8d383"))
	combo.size.x = 470
	combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var roll := Button.new()
	roll.text = "ROLL THE TABLE   [SPACE]"
	roll.position = Vector2(235, 536)
	roll.size = Vector2(310, 43)
	roll.pressed.connect(GameManager.roll_all_dice)
	roll.focus_mode = Control.FOCUS_NONE
	add_child(roll)
	_label("Click to roll  ·  Drag to arrange  ·  Hover to inspect", Vector2(198, 589), 13, Color("#b6b8a7"))
	toast = _label("", Vector2(32, 615), 13, Color("#d6c49c"))
	toast.size.x = 1060
	feedback = FeedbackManager.new()
	feedback.settings = session.state.settings
	add_child(feedback)
	audio = AudioService.new()
	audio.settings = session.state.settings
	add_child(audio)
	shop = ShopPanel.new()
	shop.on_notice = notify
	shop.on_prestige = ask_prestige
	shop.on_reset = ask_reset
	add_child(shop)
	shop.setup(session)
	session.events.changed.connect(func(): hud_dirty = true)
	session.events.die_roll_started.connect(on_roll)
	session.events.die_landed.connect(on_land)
	session.events.combo_triggered.connect(on_combo)
	session.events.purchased.connect(on_purchase)
	session.events.achievement_unlocked.connect(func(id: String): notify("Milestone unlocked · " + id))
	session.events.prestige_completed.connect(on_prestige)
	add_child(confirm)
	confirm.title = "A fresh beginning"
	confirm.min_size = Vector2i(480, 180)
	refresh()
	if SaveManager.offline_amount > 0:
		notify("Welcome back. Your table earned $" + NumberFormat.compact(SaveManager.offline_amount) + " while you were away.")
	elif not SaveManager.status.is_empty():
		notify(SaveManager.status)
	if not session.registry.errors.is_empty():
		notify("Some content could not load. Check the Godot error log.")
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--dev"):
		_build_debug()
	if OS.get_cmdline_user_args().has("--screenshot"):
		_capture_later()

func _label(text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func refresh() -> void:
	wallet.text = "$" + NumberFormat.compact(session.state.money)
	fate.text = "FATE  %d" % session.state.prestige_points
	var eps: float = session.automation.expected_income(session)
	income.text = "~$%s / sec  ·  %d dice" % [NumberFormat.compact(eps), session.state.dice.size()]
	StatisticsService.check_achievements(session.state, session.events)
	hint.text = "Click your die to begin." if session.state.tutorial_step == 0 else ("Save $20 for your second D6, or try an Amber D4." if session.state.dice.size() == 1 else ("Roll together: doubles, triples and straights!" if session.economy.modifier("combos") > 1 else "Your table is growing. Table harmony unlocks combinations."))
	for die in session.state.dice:
		if not visuals.has(die.id):
			var visual: DiceVisual = preload("res://scenes/d_6.tscn").instantiate()
			table.add_child(visual)
			visual.setup(die, session.registry.dice[die.definition_id])
			visual.selected.connect(func(id: int): session.request_roll([id]))
			visual.moved.connect(func(id: int, at: Vector2): session.move_die(id, at))
			visuals[die.id] = visual
		visuals[die.id].set_density(session.state.dice.size())
	for id in visuals.keys():
		if session.state.find_die(id) == null:
			visuals[id].queue_free()
			visuals.erase(id)
	shop.update_rows()

func on_roll(outcome: Dictionary) -> void:
	if visuals.has(outcome.die_id):
		visuals[outcome.die_id].start(outcome, session.state.settings)
	if outcome.die_id % 4 == 0 or session.pending.size() < 4:
		audio.play("roll")

func on_land(outcome: Dictionary) -> void:
	if visuals.has(outcome.die_id):
		visuals[outcome.die_id].land(outcome, session.state.settings)
	if session.state.dice.size() > 30:
		feedback.accumulate(outcome.payout)
	else:
		feedback.payout(outcome.payout, outcome.position, outcome.face == outcome.sides or outcome.critical)
	if outcome.die_id % 4 == 0 or session.pending.size() < 4:
		audio.play("max" if outcome.face == outcome.sides or outcome.critical else "land")
	if session.state.settings.flashes and (wallet_tween == null or not wallet_tween.is_running()):
		wallet.modulate = Color(1.2, 1.1, 0.8)
		wallet_tween = create_tween()
		wallet_tween.tween_property(wallet, "modulate", Color.WHITE, 0.25)

func on_combo(label: String, multiplier: float) -> void:
	combo.text = "%s  ×%d" % [label, int(multiplier)]
	combo_time = 2
	audio.play("combo")

func on_purchase(_kind: String, _id: String) -> void:
	audio.play("buy")
	notify("A little more possibility.")
	refresh()

func on_prestige() -> void:
	feedback.clear()
	combo_time = 0
	combo.text = ""
	refresh()
	notify("A fresh table. A familiar feeling. Fate remembers.")
	audio.play("combo")
	shop.show_page("Fate")

func notify(message: String) -> void:
	toast.text = message
	toast_time = 8

func _process(delta: float) -> void:
	elapsed += delta
	toast_time -= delta
	combo_time -= delta
	if toast_time <= 0:
		toast.text = SaveManager.status if SaveManager.status != "Saved" else "Progress saved · " + str(session.state.dice.size()) + " dice at the table"
	if combo_time <= 0:
		combo.text = ""
	if elapsed >= 0.4:
		elapsed = 0
		if hud_dirty:
			refresh()
			hud_dirty = false
		shop.update_rows()
	_update_helpers()

func _update_helpers() -> void:
	while workers.size() < session.automation.workers.size():
		var sprite := Sprite2D.new()
		sprite.texture = preload("res://assets/exported/helpers/moss.png")
		sprite.hframes = 12
		sprite.scale = Vector2(2, 2)
		table.add_child(sprite)
		workers.append(sprite)
	while workers.size() > session.automation.workers.size():
		workers.pop_back().queue_free()
	for index in workers.size():
		var worker: Dictionary = session.automation.workers[index]
		workers[index].position = (worker.position as Vector2).round()
		var base: int = {"idle": 0, "walk": 2, "interact": 6, "roll": 8, "celebrate": 10}.get(worker.phase, 0)
		workers[index].frame = base + int(Time.get_ticks_msec() / 160) % 2

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and not confirm.visible:
			GameManager.roll_all_dice()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3 and debug_panel != null:
			debug_panel.visible = not debug_panel.visible

func ask_prestige() -> void:
	_disconnect_confirmation()
	confirm.dialog_text = "Earn %d Fate and begin again?\nResets money, dice, helpers and ordinary upgrades.\nKeeps talents, Fate, lifetime statistics and settings." % session.progression.fate_reward()
	confirm.confirmed.connect(func():
		session.prestige()
		SaveManager.save_game()
	, CONNECT_ONE_SHOT)
	confirm.popup_centered()

func ask_reset() -> void:
	_disconnect_confirmation()
	confirm.dialog_text = "Reset ALL progression, including Fate and talents?\nYour current save will be archived first."
	confirm.confirmed.connect(func():
		if SaveManager.store != null and SaveManager.store.protected:
			notify("Resolve the protected save before resetting.")
			return
		SaveManager.save_game()
		if SaveManager.store != null and FileAccess.file_exists(SaveManager.store.path):
			var err: Error = DirAccess.copy_absolute(SaveManager.store.path, SaveManager.store.path + ".reset-" + str(int(Time.get_unix_time_from_system())))
			if err != OK:
				notify("Could not archive your save. Reset cancelled.")
				return
		GameManager.session = GameSession.new(GameManager.registry)
		SaveManager.save_game()
		get_tree().reload_current_scene()
	, CONNECT_ONE_SHOT)
	confirm.popup_centered()

func _disconnect_confirmation() -> void:
	for connection in confirm.confirmed.get_connections():
		confirm.confirmed.disconnect(connection.callable)

func _build_debug() -> void:
	debug_panel = PanelContainer.new()
	debug_panel.position = Vector2(40, 145)
	debug_panel.size = Vector2(215, 370)
	debug_panel.z_index = 90
	add_child(debug_panel)
	var box := VBoxContainer.new()
	debug_panel.add_child(box)
	for title in ["+1K", "+1M", "Force max", "Force min", "Normal RNG", "Hire helper", "Speed x1", "Speed x2", "Speed x10", "Pause / resume"]:
		var button := Button.new()
		button.text = title
		button.pressed.connect(func():
			match title:
				"+1K": session.economy.credit(1000)
				"+1M": session.economy.credit(1000000)
				"Force max": session.forced_face = -1
				"Force min": session.forced_face = 1
				"Normal RNG": session.forced_face = 0
				"Hire helper": session.state.helpers = mini(8, session.state.helpers + 1)
				"Speed x1": Engine.time_scale = 1
				"Speed x2": Engine.time_scale = 2
				"Speed x10": Engine.time_scale = 10
				"Pause / resume": session.paused = not session.paused
			refresh()
		)
		box.add_child(button)
	debug_panel.visible = false

func _capture_later() -> void:
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var destination: String = "user://preview.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			destination = argument.trim_prefix("--capture=")
	get_viewport().get_texture().get_image().save_png(destination)
	get_tree().quit()
