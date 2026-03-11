extends Node

# Each recipe: { "ingredients": { "Item": count, ... }, "result": "Item", "result_count": int }
# Organized by station type

var recipes: Dictionary = {
	"Drying Rack": [
		{
			"ingredients": {"Generic Plant": 2},
			"result": "Dried Plant",
			"result_count": 1,
		},
		{
			"ingredients": {"Herb": 2},
			"result": "Dried Herb",
			"result_count": 1,
		},
		{
			"ingredients": {"Leafy Plant": 2},
			"result": "Dried Leaves",
			"result_count": 1,
		},
		{
			"ingredients": {"Pepper": 2},
			"result": "Dried Pepper",
			"result_count": 1,
		},
	],
	"Mortar & Pestle": [
		{
			"ingredients": {"Dried Herb": 1},
			"result": "Herb Powder",
			"result_count": 1,
		},
		{
			"ingredients": {"Dried Pepper": 1},
			"result": "Pepper Spice",
			"result_count": 1,
		},
		{
			"ingredients": {"Dried Leaves": 2},
			"result": "Leaf Paste",
			"result_count": 1,
		},
	],
	"Kettle": [
		{
			"ingredients": {"Dried Herb": 1, "Dried Leaves": 1},
			"result": "Herbal Tea",
			"result_count": 1,
		},
		{
			"ingredients": {"Herb Powder": 1, "Dried Plant": 1},
			"result": "Plant Tonic",
			"result_count": 1,
		},
	],
	"Press": [
		{
			"ingredients": {"Leafy Plant": 3},
			"result": "Plant Oil",
			"result_count": 1,
		},
		{
			"ingredients": {"Pepper": 3},
			"result": "Hot Sauce",
			"result_count": 1,
		},
	],
	"Bouquet Table": [
		{
			"ingredients": {"Generic Plant": 1, "Herb": 1, "Leafy Plant": 1},
			"result": "Mixed Bouquet",
			"result_count": 1,
		},
		{
			"ingredients": {"Generic Plant": 3},
			"result": "Simple Bouquet",
			"result_count": 1,
		},
	],
}

func get_recipes_for_station(station_type: String) -> Array:
	return recipes.get(station_type, [])

func can_craft(recipe: Dictionary) -> bool:
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		return false
	for item_name in recipe["ingredients"]:
		if not inventory.has_item(item_name, recipe["ingredients"][item_name]):
			return false
	return true

func craft(recipe: Dictionary) -> bool:
	if not can_craft(recipe):
		return false
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		return false
	# Consume ingredients
	for item_name in recipe["ingredients"]:
		inventory.remove_item(item_name, recipe["ingredients"][item_name])
	# Add result
	inventory.add_item(recipe["result"], recipe["result_count"])
	print("[Crafting] Made %s x%d" % [recipe["result"], recipe["result_count"]])
	return true
