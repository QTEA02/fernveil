extends Area2D

@export var item_name: String = "Item"
@export var quantity: int = 1
@export var message: String = ""

func interact() -> void:
	var text := message
	if text == "":
		if quantity > 1:
			text = "Picked up %d %s!" % [quantity, item_name]
		else:
			text = "Picked up %s!" % item_name
	print(text)
	# TODO: add to inventory when inventory system exists
	queue_free()
