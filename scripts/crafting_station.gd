extends Area2D

@export var station_type: String = "Drying Rack"

# Station colors for placeholder visuals
var station_colors: Dictionary = {
	"Drying Rack": Color(0.55, 0.35, 0.2),
	"Mortar & Pestle": Color(0.45, 0.45, 0.5),
	"Kettle": Color(0.3, 0.3, 0.35),
	"Press": Color(0.4, 0.3, 0.2),
	"Bouquet Table": Color(0.35, 0.5, 0.3),
}

func _ready() -> void:
	# Set interaction layer
	collision_layer = 2
	collision_mask = 0

	# Build placeholder visual if no Sprite2D child exists
	if not get_node_or_null("Sprite2D"):
		_build_placeholder()

func _build_placeholder() -> void:
	var color = station_colors.get(station_type, Color(0.4, 0.4, 0.4))

	# Colored box
	var rect = ColorRect.new()
	rect.name = "PlaceholderRect"
	rect.color = color
	rect.size = Vector2(32, 32)
	rect.position = Vector2(-16, -16)
	add_child(rect)

	# Border
	var border = ColorRect.new()
	border.name = "PlaceholderBorder"
	border.color = color.lightened(0.3)
	border.size = Vector2(34, 34)
	border.position = Vector2(-17, -17)
	border.z_index = -1
	add_child(border)

	# Label
	var label = Label.new()
	label.name = "PlaceholderLabel"
	label.text = station_type
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -30)
	label.size = Vector2(80, 16)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

	# Interaction collision (if missing)
	if not get_node_or_null("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(36, 36)
		col.shape = shape
		add_child(col)

	# Physics collision (if missing)
	if not get_node_or_null("StaticBody2D"):
		var body = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var body_col = CollisionShape2D.new()
		var body_shape = RectangleShape2D.new()
		body_shape.size = Vector2(30, 30)
		body_col.shape = body_shape
		body.add_child(body_col)
		add_child(body)

func interact() -> void:
	var crafting_ui = get_node_or_null("/root/world/CraftingUI")
	if crafting_ui:
		crafting_ui.open(station_type)
	else:
		print("No CraftingUI found!")
