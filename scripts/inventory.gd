extends Node

signal item_added(item_name: String, new_total: int)
signal item_removed(item_name: String, new_total: int)
signal inventory_changed()
signal selected_seed_changed(seed_name: String)

# items = { "Mushroom": 3, "Wildflower": 1, ... }
var items: Dictionary = {}
var selected_seed: String = ""

# Maps item names to crop columns in plants.png
var seed_columns: Dictionary = {
	"Generic Plant": 0,
	"Herb": 1,
	"Leafy Plant": 2,
	"Pepper": 3,
}

func _ready() -> void:
	# Start with some seeds
	add_item("Generic Plant", 3)
	add_item("Herb", 3)
	add_item("Leafy Plant", 3)
	add_item("Pepper", 3)

func select_seed(item_name: String) -> void:
	if item_name == selected_seed:
		selected_seed = ""
		print("[Inventory] Deselected seed")
	else:
		selected_seed = item_name
		print("[Inventory] Selected seed: %s" % item_name)
	selected_seed_changed.emit(selected_seed)

func get_seed_column() -> int:
	return seed_columns.get(selected_seed, -1)

func is_seed(item_name: String) -> bool:
	return item_name in seed_columns

func add_item(item_name: String, quantity: int = 1) -> void:
	if items.has(item_name):
		items[item_name] += quantity
	else:
		items[item_name] = quantity
	item_added.emit(item_name, items[item_name])
	inventory_changed.emit()
	print("[Inventory] +%d %s (total: %d)" % [quantity, item_name, items[item_name]])

func remove_item(item_name: String, quantity: int = 1) -> bool:
	if not items.has(item_name) or items[item_name] < quantity:
		return false
	items[item_name] -= quantity
	if items[item_name] <= 0:
		items.erase(item_name)
		item_removed.emit(item_name, 0)
	else:
		item_removed.emit(item_name, items[item_name])
	inventory_changed.emit()
	return true

func get_item_count(item_name: String) -> int:
	return items.get(item_name, 0)

func has_item(item_name: String, quantity: int = 1) -> bool:
	return get_item_count(item_name) >= quantity

func get_all_items() -> Dictionary:
	return items.duplicate()

func clear() -> void:
	items.clear()
	inventory_changed.emit()

func print_inventory() -> void:
	if items.is_empty():
		print("[Inventory] Empty")
		return
	print("[Inventory] Contents:")
	for item_name in items:
		print("  %s x%d" % [item_name, items[item_name]])
