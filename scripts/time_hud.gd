extends CanvasLayer

@onready var time_label: Label = $TimeLabel
@onready var day_label: Label = $DayLabel
@onready var phase_label: Label = $PhaseLabel
@onready var seed_label: Label = $SeedLabel

var day_night: Node

func _ready() -> void:
	day_night = get_node_or_null("../DayNightCycle")
	if day_night:
		day_night.phase_changed.connect(_on_phase_changed)

	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		inventory.selected_seed_changed.connect(_on_seed_changed)

func _process(_delta: float) -> void:
	if day_night:
		time_label.text = day_night.get_time_string()
		day_label.text = "Day " + str(day_night.current_day)

func _on_phase_changed(new_phase: String) -> void:
	phase_label.text = new_phase

func _on_seed_changed(seed_name: String) -> void:
	if seed_name == "":
		seed_label.text = ""
	else:
		seed_label.text = "Seed: " + seed_name
