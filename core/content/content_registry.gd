class_name ContentRegistry
extends RefCounted

var dice: Dictionary = {}
var upgrades: Dictionary = {}
var talents: Dictionary = {}
var errors: PackedStringArray = []

func _init() -> void:
	_load_folder("res://dice/definitions", dice, false)
	_load_folder("res://upgrades/definitions", upgrades, true)
	_load_folder("res://talents/definitions", talents, true)
	for catalog in [upgrades, talents]:
		for id in catalog.keys():
			var definition: UpgradeDefinition = catalog[id]
			if (not definition.prerequisite.is_empty() and not catalog.has(definition.prerequisite)) or (not definition.target.is_empty() and not dice.has(definition.target)):
				errors.append("Invalid upgrade reference: " + id)
				catalog.erase(id)

func _load_folder(path: String, destination: Dictionary, is_upgrade: bool) -> void:
	var names: PackedStringArray = DirAccess.get_files_at(path)
	names.sort()
	for filename in names:
		if not filename.ends_with(".tres"):
			continue
		var resource: Resource = load(path.path_join(filename))
		var type_ok: bool = resource is UpgradeDefinition if is_upgrade else resource is DiceDefinition
		if not type_ok or not resource.valid() or destination.has(resource.id):
			errors.append(path.path_join(filename))
			continue
		if not is_upgrade and (resource.texture == null or resource.texture.get_width() != resource.sides * 32 or resource.texture.get_height() != 32):
			errors.append("Invalid face sheet: " + path.path_join(filename))
			continue
		destination[resource.id] = resource

func all_modifiers() -> Array:
	return upgrades.values() + talents.values()
