extends RefCounted

const PATH := "user://journey.cfg"


static func empty(language := 0) -> Dictionary:
	return {"language": language, "open": 1, "level": 0, "point": -1, "items": [],
		"won": false, "gravity_time": 0.0}

static func load_game(path := PATH) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK and config.load(path + ".previous") != OK:
		return empty()
	var result := empty()
	for key in result:
		result[key] = config.get_value("journey", key, result[key])
	result.language = clampi(int(result.language), 0, 2)
	result.open = clampi(int(result.open), 1, 3)
	result.level = clampi(int(result.level), 0, result.open)
	result.point = clampi(int(result.point), -1, 2) if result.level in [1, 2] else -1
	result.gravity_time = clampf(float(result.gravity_time), 0.0, 23.0)
	var items := []
	if result.items is Array:
		for item in result.items:
			if item is int and item in range(5) and item not in items:
				items.append(item)
	result.items = items
	return result

static func save_game(state: Dictionary, path := PATH) -> Error:
	var config := ConfigFile.new()
	for key in state:
		config.set_value("journey", key, state[key])
	var staged := path + ".tmp"
	var error := config.save(staged)
	if error != OK:
		return error
	var backup := path + ".previous"
	if FileAccess.file_exists(path):
		error = DirAccess.rename_absolute(path, backup)
		if error != OK:
			return error
	error = DirAccess.rename_absolute(staged, path)
	if error == OK and FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	return error
