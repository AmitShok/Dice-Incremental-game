extends Control

@export var die_scene: PackedScene = preload("res://scenes/d_6.tscn")
@export var helper_scene: PackedScene = preload("res://scenes/helpers/moss.tscn")

var session: GameSession
@onready var table: Node2D = $Tabletop/Dice
@onready var helper_layer: Node2D = $Tabletop/Helpers
var visuals: Dictionary = {}
var workers: Array[Sprite2D] = []
@onready var wallet: Label = $HUD/Wallet
@onready var income: Label = $HUD/Income
@onready var fate: Label = $HUD/Fate
@onready var hint: Label = $HUD/Hint
@onready var toast: Label = $HUD/Toast
@onready var combo: Label = $HUD/Combo
@onready var shop: ShopPanel = $ShopPanel
@onready var feedback: FeedbackManager = $Feedback
@onready var audio: AudioService = $Audio
var elapsed: float = 0.0
var toast_time: float = 0.0
var combo_time: float = 0.0
var debug_panel: PanelContainer
@onready var confirm: ConfirmationDialog = $Confirm
var hud_dirty: bool = false
var wallet_tween: Tween

func _ready() -> void:
	session = GameManager.session
	$HUD/RollButton.pressed.connect(GameManager.roll_all_dice)
	feedback.settings = session.state.settings
	audio.settings = session.state.settings
	shop.on_notice = notify
	shop.on_prestige = ask_prestige
	shop.on_reset = ask_reset
	shop.setup(session)
	session.events.changed.connect(func(): hud_dirty = true)
	session.events.die_roll_started.connect(on_roll)
	session.events.die_landed.connect(on_land)
	session.events.combo_triggered.connect(on_combo)
	session.events.purchased.connect(on_purchase)
	session.events.achievement_unlocked.connect(func(id: String): notify("Milestone unlocked · " + id))
	session.events.prestige_completed.connect(on_prestige)
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

func refresh() -> void:
	wallet.text = "$" + NumberFormat.compact(session.state.money)
	fate.text = "FATE  %d" % session.state.prestige_points
	var eps: float = session.automation.expected_income(session)
	income.text = "~$%s / sec  ·  %d dice" % [NumberFormat.compact(eps), session.state.dice.size()]
	StatisticsService.check_achievements(session.state, session.events)
	hint.text = "Click your die to begin." if session.state.tutorial_step == 0 else ("Save $20 for your second D6, or try an Amber D4." if session.state.dice.size() == 1 else ("Roll together: doubles, triples and straights!" if session.economy.modifier("combos") > 1 else "Your table is growing. Table harmony unlocks combinations."))
	for die in session.state.dice:
		if not visuals.has(die.id):
			var visual: DiceVisual = die_scene.instantiate()
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
		var sprite: Sprite2D = helper_scene.instantiate()
		helper_layer.add_child(sprite)
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
	debug_panel = $DebugPanel
	for button in debug_panel.get_node("Buttons").get_children():
		var title: String = button.text
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
