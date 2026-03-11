extends TileMapLayer

# Atlas source IDs and tile coords — set these after adding atlases in the editor
# Source 0 = ground tileset (already exists)
# Source 1 = rocks (already exists)
# Source 2 = plants atlas (add in editor)

# Tile coords in the plants atlas for each growth stage (column 0 = first crop)
# Each crop type uses a different column in the plants.png spritesheet
@export var soil_source_id: int = 0
@export var soil_atlas_coord: Vector2i = Vector2i(0, 0)
@export var crop_source_id: int = 2
@export var grow_time: float = 10.0

# Crop types: each is a column in plants.png
# Column 0 = generic, 1 = herb, 2 = leafy, 3 = pepper, 4 = cabbage, 5 = berry, 6 = corn
var crop_stages: Dictionary = {
	# cell position -> { "stage": int, "max_stages": int, "column": int, "timer": float }
}

var stage_coords: Array[Array] = [
	# Each sub-array is the atlas coords for growth stages of that column
	# These map to rows in the plants.png atlas (y = row index)
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)],  # column 0
	[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4)],  # column 1
	[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4)],  # column 2
	[Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4)],  # column 3
]

@export var crop_column: int = 0

# Name of the item produced when harvesting each crop column
var crop_names: Array[String] = [
	"Generic Plant",  # column 0
	"Herb",           # column 1
	"Leafy Plant",    # column 2
	"Pepper",         # column 3
]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_crop"):
		crop_column = (crop_column + 1) % stage_coords.size()
		var name = crop_names[crop_column] if crop_column < crop_names.size() else "Crop %d" % crop_column
		print("Selected seed: %s" % name)

func _process(delta: float) -> void:
	var cells_to_advance: Array[Vector2i] = []
	for cell in crop_stages:
		var data: Dictionary = crop_stages[cell]
		if data["stage"] < data["max_stages"] - 1:
			data["timer"] += delta
			var time_per_stage: float = grow_time / data["max_stages"]
			if data["timer"] >= time_per_stage:
				data["timer"] -= time_per_stage
				cells_to_advance.append(cell)

	for cell in cells_to_advance:
		_advance_growth(cell)

func interact_at(world_pos: Vector2) -> bool:
	var cell := local_to_map(to_local(world_pos))
	var source_id := get_cell_source_id(cell)

	if source_id == -1:
		return false

	# If this cell has a growing/grown crop
	if crop_stages.has(cell):
		var data: Dictionary = crop_stages[cell]
		if data["stage"] >= data["max_stages"] - 1:
			# Harvest — reset to soil and add to inventory
			var col: int = data["column"]
			var item_name: String = "Crop"
			if col < crop_names.size():
				item_name = crop_names[col]
			set_cell(cell, soil_source_id, soil_atlas_coord)
			crop_stages.erase(cell)
			var inventory = get_node_or_null("/root/Inventory")
			if inventory:
				inventory.add_item(item_name, 1)
			print("Harvested %s!" % item_name)
			return true
		else:
			print("Growing... stage ", data["stage"] + 1, "/", data["max_stages"])
			return true

	# If this is a soil tile (no crop yet) — plant using selected seed
	if source_id == soil_source_id:
		var inventory = get_node_or_null("/root/Inventory")
		if not inventory or inventory.selected_seed == "":
			print("No seed selected! Open inventory [Tab] to select one.")
			return true

		var seed_name: String = inventory.selected_seed
		var col: int = inventory.get_seed_column()
		if col < 0 or col >= stage_coords.size():
			print("Invalid seed!")
			return true

		if not inventory.has_item(seed_name):
			print("No %s seeds left!" % seed_name)
			return true

		inventory.remove_item(seed_name, 1)
		var stages: Array = stage_coords[col]
		crop_stages[cell] = {
			"stage": 0,
			"max_stages": stages.size(),
			"column": col,
			"timer": 0.0,
		}
		set_cell(cell, crop_source_id, stages[0])
		print("Planted %s!" % seed_name)
		return true

	return false

func _advance_growth(cell: Vector2i) -> void:
	var data: Dictionary = crop_stages[cell]
	data["stage"] += 1
	var stages: Array = stage_coords[data["column"]]
	set_cell(cell, crop_source_id, stages[data["stage"]])
	if data["stage"] >= data["max_stages"] - 1:
		print("Crop at ", cell, " is ready to harvest!")
