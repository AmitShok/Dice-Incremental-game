class_name GameEvents
extends RefCounted

signal changed
signal die_roll_started(outcome: Dictionary)
signal die_landed(outcome: Dictionary)
signal money_generated(amount: float, position: Vector2)
signal combo_triggered(label: String, multiplier: float)
signal purchased(kind: String, id: String)
signal achievement_unlocked(id: String)
signal prestige_completed
signal notice(message: String)
