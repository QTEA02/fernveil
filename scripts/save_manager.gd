extends Node

const SAVE_PATH := "user://savegame.json"

func save_game() -> bool:
	var data: Dictionary = {}

	# Inventory
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		data["inventory"] = {
			"items": inventory.items.duplicate(),
			"selected_seed": inventory.selected_seed,
		}

	# Day/Night Cycle
	var cycle = get_node_or_null("/root/world/DayNightCycle")
	if cycle:
		data["day_night"] = {
			"current_hour": cycle.current_hour,
			"current_minute": cycle.current_minute,
			"current_day": cycle.current_day,
			"minute_accumulator": cycle.minute_accumulator,
		}

	# Player position
	var player = get_node_or_null("/root/world/Player")
	if player:
		data["player"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
		}

	# Farm layer crops
	var farm = get_node_or_null("/root/world/FarmLayer")
	if farm:
		var crops: Dictionary = {}
		for cell in farm.crop_stages:
			var key := "%d,%d" % [cell.x, cell.y]
			var crop_data: Dictionary = farm.crop_stages[cell]
			crops[key] = {
				"stage": crop_data["stage"],
				"max_stages": crop_data["max_stages"],
				"column": crop_data["column"],
				"timer": crop_data["timer"],
			}
		data["farm_crops"] = crops

	# Write to file
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		print("[SaveManager] Failed to save: ", FileAccess.get_open_error())
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveManager] Game saved!")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("[SaveManager] Failed to open save file.")
		return false

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var result := json.parse(json_text)
	if result != OK:
		print("[SaveManager] Failed to parse save file: ", json.get_error_message())
		return false

	var data: Dictionary = json.data

	# Inventory
	if data.has("inventory"):
		var inventory = get_node_or_null("/root/Inventory")
		if inventory:
			inventory.items.clear()
			var saved_items: Dictionary = data["inventory"]["items"]
			for item_name in saved_items:
				inventory.items[item_name] = int(saved_items[item_name])
			inventory.selected_seed = data["inventory"]["selected_seed"]
			inventory.inventory_changed.emit()
			inventory.selected_seed_changed.emit(inventory.selected_seed)

	# Day/Night Cycle
	if data.has("day_night"):
		var cycle = get_node_or_null("/root/world/DayNightCycle")
		if cycle:
			cycle.current_hour = int(data["day_night"]["current_hour"])
			cycle.current_minute = int(data["day_night"]["current_minute"])
			cycle.current_day = int(data["day_night"]["current_day"])
			cycle.minute_accumulator = float(data["day_night"]["minute_accumulator"])
			cycle._update_phase()
			cycle._update_color()

	# Player position
	if data.has("player"):
		var player = get_node_or_null("/root/world/Player")
		if player:
			player.global_position = Vector2(
				float(data["player"]["x"]),
				float(data["player"]["y"])
			)

	# Farm layer crops
	if data.has("farm_crops"):
		var farm = get_node_or_null("/root/world/FarmLayer")
		if farm:
			# Clear existing crops — reset tiles to soil
			for cell in farm.crop_stages.keys():
				farm.set_cell(cell, farm.soil_source_id, farm.soil_atlas_coord)
			farm.crop_stages.clear()

			var saved_crops: Dictionary = data["farm_crops"]
			for key in saved_crops:
				var parts: PackedStringArray = key.split(",")
				var cell := Vector2i(int(parts[0]), int(parts[1]))
				var crop_data: Dictionary = saved_crops[key]
				var stage: int = int(crop_data["stage"])
				var column: int = int(crop_data["column"])
				farm.crop_stages[cell] = {
					"stage": stage,
					"max_stages": int(crop_data["max_stages"]),
					"column": column,
					"timer": float(crop_data["timer"]),
				}
				# Restore the tile visual
				if column < farm.stage_coords.size():
					var stages: Array = farm.stage_coords[column]
					if stage < stages.size():
						farm.set_cell(cell, farm.crop_source_id, stages[stage])

	print("[SaveManager] Game loaded!")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Save deleted.")
