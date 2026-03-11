extends Area2D

enum State { EMPTY, GROWING, HARVESTABLE }

@export var crop_name: String = "Plant"
@export var grow_time: float = 10.0
@export var stage_regions: Array[Rect2] = [
	Rect2(0, 0, 32, 64),      # seed/tiny sprout
	Rect2(0, 64, 32, 64),     # small plant
	Rect2(0, 128, 32, 64),    # medium plant
	Rect2(0, 192, 32, 64),    # large plant
	Rect2(0, 256, 32, 64),    # fully grown / harvestable
]

var state: State = State.EMPTY
var current_stage: int = 0

@onready var crop_sprite: Sprite2D = $CropSprite
@onready var soil_sprite: Sprite2D = $SoilSprite
@onready var grow_timer: Timer = $GrowTimer

func _ready() -> void:
	crop_sprite.visible = false
	grow_timer.wait_time = grow_time / stage_regions.size()
	grow_timer.timeout.connect(_on_grow_tick)

func interact() -> void:
	match state:
		State.EMPTY:
			_plant()
		State.GROWING:
			print("Growing... stage ", current_stage, "/", stage_regions.size())
		State.HARVESTABLE:
			_harvest()

func _plant() -> void:
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory or inventory.selected_seed == "":
		print("No seed selected! Open inventory [Tab] to select one.")
		return

	var seed_name: String = inventory.selected_seed
	if not inventory.has_item(seed_name):
		print("No %s seeds left!" % seed_name)
		return

	# Consume the seed and set crop_name to match
	inventory.remove_item(seed_name, 1)
	crop_name = seed_name

	# Update sprite column based on seed type
	var col: int = inventory.get_seed_column()
	if col >= 0:
		for i in stage_regions.size():
			stage_regions[i].position.x = col * 32

	state = State.GROWING
	current_stage = 0
	crop_sprite.visible = true
	crop_sprite.region_rect = stage_regions[0]
	grow_timer.start()
	print("Planted ", crop_name, "!")

func _on_grow_tick() -> void:
	current_stage += 1
	if current_stage >= stage_regions.size():
		state = State.HARVESTABLE
		crop_sprite.region_rect = stage_regions[stage_regions.size() - 1]
		grow_timer.stop()
		print(crop_name, " is ready to harvest!")
	else:
		crop_sprite.region_rect = stage_regions[current_stage]

func _harvest() -> void:
	state = State.EMPTY
	current_stage = 0
	crop_sprite.visible = false
	grow_timer.stop()
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		inventory.add_item(crop_name, 1)
	print("Harvested ", crop_name, "!")
