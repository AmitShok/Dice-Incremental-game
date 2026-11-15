extends SceneTree
var failures: int = 0
func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func touch(at: Vector2, down: bool, canceled: bool = false) -> void:
 var event := InputEventScreenTouch.new()
 event.index = 0
 event.position = root.get_final_transform() * at
 event.pressed = down
 event.canceled = canceled
 Input.parse_input_event(event)
 await process_frame
func drag(from: Vector2, to: Vector2) -> void:
 var previous: Vector2 = from
 for step in range(1, 9):
  var at: Vector2 = from.lerp(to, step / 8.0)
  var event := InputEventScreenDrag.new()
  event.index = 0
  event.position = root.get_final_transform() * at
  event.relative = root.get_final_transform().basis_xform(at - previous)
  event.velocity = event.relative * 60
  Input.parse_input_event(event)
  previous = at
  await process_frame
func run() -> void:
 if not OS.get_cmdline_user_args().has("--test"):
  quit(1)
  return
 # Also enables touchscreen detection on desktop CI; inject real touch events below.
 Input.emulate_touch_from_mouse = true
 Input.emulate_mouse_from_touch = true
 if OS.get_cmdline_user_args().has("--phone"):
  root.size = Vector2i(844, 390)
 var game: GameSession = root.get_node("GameManager").session
 game.state.money = 100000
 game.state.run_earned = 100000
 var main: Control = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 await process_frame
 for page in ["Dice", "Upgrades", "Helpers", "Settings"]:
  main.shop.show_page(page)
  await process_frame
  await process_frame
  var button: Button
  if page == "Settings":
   button = main.shop.body.get_node("SettingsPage/sound")
  else:
   button = main.shop.rows[0].button
  var at: Vector2 = button.get_global_rect().get_center()
  var money: float = game.state.money
  var dice: int = game.state.dice.size()
  var sound: bool = game.state.settings.sound
  await touch(at, true)
  await drag(at, at - Vector2(0, 100))
  await touch(at - Vector2(0, 100), false)
  check(main.shop.scroll.scroll_vertical > 30, "Finger swipe scrolls " + page)
  check(game.state.money == money and game.state.dice.size() == dice and game.state.settings.sound == sound and not main.get_node("Confirm").visible, "Swipe does not activate " + page)
  # Finish the native inertial gesture before rebuilding the page.
  await touch(Vector2(1000, 450), true)
  await touch(Vector2(1000, 450), false, true)
 main.shop.show_page("Dice")
 await process_frame
 await process_frame
 var buy: Button = main.shop.rows[0].button
 var before: int = game.state.dice.size()
 await touch(buy.get_global_rect().get_center(), true)
 await touch(buy.get_global_rect().get_center(), false)
 check(game.state.dice.size() == before + 1, "Single touch purchase happens exactly once")
 var settings_button: Button = main.shop.get_node("Footer/Settings")
 await touch(settings_button.get_global_rect().get_center(), true)
 await touch(settings_button.get_global_rect().get_center(), false)
 check(main.shop.page == "Settings", "Touch opens Settings")
 await process_frame
 var sound_button: Button = main.shop.body.get_node("SettingsPage/sound")
 var old_sound: bool = game.state.settings.sound
 await touch(sound_button.get_global_rect().get_center(), true)
 await touch(sound_button.get_global_rect().get_center(), false)
 check(game.state.settings.sound != old_sound, "Touch toggles a setting once")
 main.shop.show_page("Dice")
 await process_frame
 var wheel := InputEventMouseButton.new()
 wheel.position = root.get_final_transform() * Vector2(1000, 400)
 wheel.global_position = wheel.position
 wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
 wheel.pressed = true
 Input.parse_input_event(wheel)
 var wheel_release: InputEventMouseButton = wheel.duplicate()
 wheel_release.pressed = false
 Input.parse_input_event(wheel_release)
 await process_frame
 check(main.shop.scroll.scroll_vertical > 0, "Mouse wheel still scrolls")
 var die: DiceInstance = game.state.dice[0]
 var origin: Vector2 = die.position
 await touch(origin, true)
 await drag(origin, origin + Vector2(3, 2))
 await touch(origin + Vector2(3, 2), false)
 check(die.busy, "Slight finger jitter still taps to roll")
 game.settle()
 die.cooldown = 0
 origin = die.position
 await touch(origin, true)
 await drag(origin, origin + Vector2(50, 25))
 await touch(origin + Vector2(50, 25), false)
 check(not die.busy and die.position.distance_to(origin) > 30, "Finger drag moves dice without rolling")
 origin = die.position
 await touch(origin, true)
 await drag(origin, origin + Vector2(30, 20))
 await touch(origin + Vector2(30, 20), false, true)
 check(not die.busy and die.position == origin, "Canceled touch does not roll or commit movement")
 # Fate tab on a phone: the tree opens, and a second tap or a browser's follow-up click on the
 # same spot must not close it (Close used to sit right under the Fate tab).
 main.shop.show_page("Dice")
 await process_frame
 var fate_tab: Button = main.shop.get_node("Tabs/Fate")
 var fate_at: Vector2 = fate_tab.get_global_rect().get_center()
 await touch(fate_at, true)
 await touch(fate_at, false)
 check(main.talents.visible, "Tapping the Fate tab opens the talent tree")
 # Every talent is laid out on screen at once, with no scroll area (clipped scroll areas drew
 # nothing on iPhone browsers).
 await process_frame
 var panel: Rect2 = main.talents.get_global_rect()
 var all_inside: bool = main.talents.find_children("*", "ScrollContainer", true, false).is_empty()
 for node in main.talents.nodes.values():
  all_inside = all_inside and panel.encloses(node.get_global_rect()) and node.is_visible_in_tree()
 check(all_inside and main.talents.nodes.size() == main.session.registry.talents.size(), "All talents are visible on screen without scrolling")
 await touch(fate_at, true)
 await touch(fate_at, false)
 check(main.talents.visible, "A second tap on the Fate tab spot keeps the talent tree open")
 var close: Button = main.talents.find_child("Close", true, false)
 check(close != null and not close.get_global_rect().has_point(fate_at), "Close is not under the Fate tab")
 await create_timer(0.5).timeout
 await touch(close.get_global_rect().get_center(), true)
 await touch(close.get_global_rect().get_center(), false)
 check(not main.talents.visible, "Close works once the tree has settled")
 print("TOUCH RESULT: ", failures, " failures")
 # Let the last purchase sound finish so no audio stream is still in use at exit.
 await create_timer(0.8).timeout
 quit(1 if failures else 0)
