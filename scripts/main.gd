extends Control

@export var die_scene: PackedScene = preload("res://scenes/d_6.tscn")
@export var helper_scene: PackedScene = preload("res://scenes/helpers/moss.tscn")
@export var developer_tools_enabled: bool = true

var session: GameSession
@onready var table: Node2D = $Tabletop/Dice
@onready var surface: Sprite2D = $Tabletop/Surface
var shown_table: String = ""
@onready var helper_layer: Node2D = $Tabletop/Helpers
var visuals: Dictionary = {}
var workers: Array[Sprite2D] = []
@onready var wallet: Label = $HUD/Wallet
@onready var income: Label = $HUD/Income
@onready var fate: Label = $HUD/Fate
@onready var chips: Label = $HUD/House
@onready var hint: Label = $HUD/Hint
@onready var toast: Label = $HUD/Toast
@onready var combo: Label = $HUD/Combo
@onready var streak_box: Control = $HUD/Streak
@onready var streak_label: Label = $HUD/Streak/Label
@onready var streak_bar: ProgressBar = $HUD/Streak/Bar
@onready var sell_tray: PanelContainer = $HUD/SellTray
@onready var sell_label: Label = $HUD/SellTray/Label
const HATS_TEXTURE_PATH: String = "res://assets/exported/helpers/hats.png"
@onready var shop: ShopPanel = $ShopPanel
@onready var feedback: FeedbackManager = $Feedback
@onready var audio: AudioService = $Audio
var elapsed: float = 0.0
var toast_time: float = 0.0
var combo_time: float = 0.0
var debug_panel: PanelContainer
@onready var confirm: ConfirmationDialog = $Confirm
var talents: TalentTree
var hud_dirty: bool = false
var wallet_tween: Tween

func _ready() -> void:
	session = GameManager.session
	$HUD/RollButton.pressed.connect(GameManager.roll_all_dice)
	feedback.settings = session.state.settings
	audio.settings = session.state.settings
	audio.apply_settings()
	shop.on_settings_changed = audio.apply_settings
	shop.on_notice = notify
	shop.on_prestige = ask_prestige
	shop.on_reset = ask_reset
	shop.on_developer_tools = open_developer_tools
	shop.developer_tools_enabled = developer_tools_enabled and OS.is_debug_build()
	talents = TalentTree.new()
	add_child(talents)
	move_child(talents, confirm.get_index())
	talents.setup(session)
	talents.on_prestige = ask_prestige
	talents.on_notice = notify
	shop.on_fate = talents.open
	_add_fate_plaque_button()
	shop.setup(session)
	session.events.changed.connect(func(): hud_dirty = true)
	session.events.die_roll_started.connect(on_roll)
	session.events.die_landed.connect(on_land)
	session.events.combo_triggered.connect(on_combo)
	session.events.purchased.connect(on_purchase)
	session.events.achievement_unlocked.connect(func(id: String): notify("Milestone unlocked · " + id))
	session.events.prestige_completed.connect(on_prestige)
	session.events.effect_triggered.connect(on_effect)
	session.events.die_sold.connect(on_sold)
	session.events.table_unlocked.connect(func(id: String): notify("New table unlocked · " + TableCatalog.TABLES[id].name + ". Pick it on the Tables page."))
	session.events.streak_stage_changed.connect(on_streak_stage)
	refresh()
	if session.talent_refund > 0:
		notify("The talent tree grew! Your %d spent Fate is back. Each Fate you hold now makes every roll pay 1%% more." % session.talent_refund)
	elif session.migration_refund > 0:
		notify("Auto-rolling is now done by helpers. Refunded $" + NumberFormat.compact(session.migration_refund) + " for your enchanted dice.")
	elif SaveManager.offline_amount > 0:
		notify("Welcome back. Your table earned $" + NumberFormat.compact(SaveManager.offline_amount) + " while you were away.")
	elif not SaveManager.status.is_empty():
		notify(SaveManager.status)
	if not session.registry.errors.is_empty():
		notify("Some content could not load. Check the Godot error log.")
	if shop.developer_tools_enabled:
		_build_debug()
	if OS.get_cmdline_user_args().has("--screenshot"):
		_capture_later()

func refresh() -> void:
	wallet.text = "$" + NumberFormat.compact(session.state.money)
	fate.text = "FATE  %d" % session.state.prestige_points
	chips.text = "CHIPS %d  ·  HATS %d/%d" % [session.state.chips, session.state.hats.size(), Cosmetics.HATS.size()]
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
			visual.dropped.connect(on_die_dropped)
			visual.drag_moved.connect(on_die_dragged)
			visuals[die.id] = visual
		visuals[die.id].set_density(session.state.dice.size())
		visuals[die.id].update_gild()
	for id in visuals.keys():
		if session.state.find_die(id) == null:
			visuals[id].queue_free()
			visuals.erase(id)
	_apply_table()
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
	if outcome.face == 1 and session.state.dice.size() <= 30:
		feedback.payout_text("+%d chip" % (2 if session.state.table_id == "starlit" else 1), outcome.position + Vector2(0, 18), Color("#ff9a8a"))
		if session.state.chips == Cosmetics.CAPSULE_COST:
			notify("25 chips! Open a hat capsule on the Helpers page.")
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

func on_purchase(kind: String, _id: String) -> void:
	if kind == "capsule":
		audio.play("capsule")
	else:
		audio.play("buy")
		notify("A little more possibility.")
	refresh()

func on_prestige() -> void:
	feedback.clear()
	combo_time = 0
	combo.text = ""
	refresh()
	notify("A fresh table. Each Fate you hold makes every roll pay 1% more.")
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
		if talents.visible:
			talents.refresh()
	_update_helpers()
	_update_streak()
	_update_fate_progress()

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
		_dress_helper(workers[index], index)

## Hats are an optional child sprite; frames follow Cosmetics.HATS[id].frame.
func _dress_helper(sprite: Sprite2D, index: int) -> void:
	var hat: Sprite2D = sprite.get_node_or_null("Hat")
	if hat == null:
		if not ResourceLoader.exists(HATS_TEXTURE_PATH):
			return
		hat = Sprite2D.new()
		hat.name = "Hat"
		hat.texture = load(HATS_TEXTURE_PATH)
		hat.hframes = Cosmetics.HATS.size()
		hat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.add_child(hat)
	var id: String = Cosmetics.hat_for(session.state, index)
	hat.visible = not id.is_empty()
	if hat.visible:
		hat.frame = Cosmetics.HATS[id].frame
		# Bob with the helper's two-frame idle/walk cycle.
		hat.position = Vector2(0, -10 - (sprite.frame % 2))

func _update_streak() -> void:
	var active: bool = session.streak >= 3
	streak_box.visible = active
	if not active:
		return
	var stage: Array = GameSession.STREAK_STAGES[session.streak_stage()]
	var title: String = stage[2] if not str(stage[2]).is_empty() else "STREAK"
	streak_label.text = "%s %d  ·  ×%s" % [title, session.streak, str(stage[1])]
	streak_bar.value = clampf(session.streak_timer / maxf(0.01, session.streak_window()), 0.0, 1.0)

func on_streak_stage(stage: int) -> void:
	if stage > 0:
		combo.text = "%s STREAK  ×%s" % [GameSession.STREAK_STAGES[stage][2], str(GameSession.STREAK_STAGES[stage][1])]
		combo_time = 1.5
		audio.play("streak")

func on_effect(action: String, from: Vector2, targets: Array) -> void:
	feedback.effect(action, from, targets)
	audio.play({"arc": "arc", "blast": "blast", "gild": "gild"}.get(action, "max"))
	if action == "gild":
		for visual in visuals.values():
			visual.update_gild()

func on_sold(amount: float, at: Vector2) -> void:
	feedback.payout_text("SOLD +$" + NumberFormat.compact(amount), sell_tray.position + sell_tray.size * 0.5, Color("#ffe0a0"))
	audio.play("sell")
	refresh()

func _sell_zone() -> Rect2:
	return Rect2(sell_tray.position, sell_tray.size)

func on_die_dragged(id: int, center: Vector2) -> void:
	if _sell_zone().has_point(center):
		sell_tray.modulate = Color(1.3, 1.15, 0.8)
		sell_label.text = "Release to sell for $%s" % NumberFormat.compact(session.sell_value(id)) if session.can_sell(id) else "Keep at least one die"
	else:
		_reset_tray()

func on_die_dropped(id: int, center: Vector2) -> void:
	_reset_tray()
	if _sell_zone().has_point(center):
		if session.sell_die(id) <= 0.0:
			notify("You need at least one die on the table.")
	else:
		session.move_die(id, center)
	if visuals.has(id):
		visuals[id].snap()

func _reset_tray() -> void:
	sell_tray.modulate = Color.WHITE
	sell_label.text = "SELL TRAY\ndrag a die here"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and not confirm.visible:
			GameManager.roll_all_dice()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3 and debug_panel != null:
			debug_panel.visible = not debug_panel.visible

func ask_prestige() -> void:
	_disconnect_confirmation()
	confirm.dialog_text = "Earn %d Fate and begin again?\nResets money, dice, helpers and ordinary upgrades.\nKeeps talents, Fate, lifetime statistics and settings.\nEach Fate you hold makes every roll pay 1%% more.%s" % [session.progression.fate_reward(), session.progression.carryover_summary()]
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

func open_developer_tools() -> void:
	if debug_panel != null:
		debug_panel.show()

func _build_debug() -> void:
	debug_panel = $DebugPanel
	debug_panel.get_node("Layout/Close").pressed.connect(func(): debug_panel.hide())
	for button in debug_panel.get_node("Layout/Scroll/Buttons").get_children():
		var title: String = button.text
		button.pressed.connect(func():
			match title:
				"+1K": session.economy.credit(1000)
				"+1M": session.economy.credit(1000000)
				"Force max": session.forced_face = -1
				"Force min": session.forced_face = 1
				"Normal RNG": session.forced_face = 0
				"Hire helper": session.state.helpers = mini(GameState.MAX_HELPERS, session.state.helpers + 1)
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

## Swaps the felt for the chosen table's surface art (assets/exported/tables/<id>.png).
func _apply_table() -> void:
	if shown_table == session.state.table_id:
		return
	shown_table = session.state.table_id
	var path: String = "res://assets/exported/tables/%s.png" % shown_table
	if ResourceLoader.exists(path):
		surface.texture = load(path)

## The Fate plaque in the header opens the talent tree; a thin bar shows progress to Fate.
func _add_fate_plaque_button() -> void:
	var plaque := Button.new()
	plaque.name = "FatePlaque"
	plaque.flat = true
	plaque.focus_mode = Control.FOCUS_NONE
	plaque.position = Vector2(790, 8)
	plaque.size = Vector2(252, 70)
	plaque.tooltip_text = "Open Fate talents. Each Fate you hold makes every roll pay 1% more."
	plaque.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	plaque.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	plaque.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	plaque.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	plaque.pressed.connect(talents.open)
	$HUD.add_child(plaque)
	var bar := ProgressBar.new()
	bar.name = "FateProgress"
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.position = Vector2(800, 70)
	bar.size = Vector2(230, 4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#b6a2e0")
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.35)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	$HUD.add_child(bar)

func _update_fate_progress() -> void:
	var bar: ProgressBar = $HUD.get_node_or_null("FateProgress")
	if bar == null:
		return
	var state: GameState = session.state
	var reward: int = session.progression.fate_reward()
	var floor_at: float = 0.0 if reward == 0 else ProgressionService.FATE_SCALE * pow(reward / session.economy.modifier("fate_gain"), 2)
	var goal: float = session.progression.next_fate_at()
	bar.value = clampf((state.run_earned - floor_at) / maxf(1.0, goal - floor_at), 0.0, 1.0)
	fate.modulate = Color(1.25, 1.15, 1.4) if reward > 0 and int(Time.get_ticks_msec() / 500) % 2 == 0 else Color.WHITE
