extends Area2D

@export var npc_name: String = "NPC"
@export var dialogue_id: String = "test_npc"
@export var sprite_color: Color = Color(1, 1, 1)

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0

	# Build placeholder visual if no Sprite2D child exists
	if not get_node_or_null("Sprite2D") and not get_node_or_null("AnimatedSprite2D"):
		_build_placeholder()

func _build_placeholder() -> void:
	# Colored rectangle as placeholder
	var rect = ColorRect.new()
	rect.name = "PlaceholderRect"
	rect.color = sprite_color
	rect.size = Vector2(24, 32)
	rect.position = Vector2(-12, -24)
	add_child(rect)

	# Head
	var head = ColorRect.new()
	head.name = "PlaceholderHead"
	head.color = sprite_color.lightened(0.2)
	head.size = Vector2(16, 16)
	head.position = Vector2(-8, -32)
	add_child(head)

	# Name label
	var label = Label.new()
	label.name = "PlaceholderLabel"
	label.text = npc_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -46)
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
		shape.size = Vector2(28, 36)
		col.shape = shape
		col.position = Vector2(0, -8)
		add_child(col)

	# Physics collision (if missing)
	if not get_node_or_null("StaticBody2D"):
		var body = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var body_col = CollisionShape2D.new()
		var body_shape = RectangleShape2D.new()
		body_shape.size = Vector2(22, 30)
		body_col.shape = body_shape
		body_col.position = Vector2(0, -8)
		body.add_child(body_col)
		add_child(body)

func interact() -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.start_dialogue(dialogue_id)
	else:
		print("%s: ..." % npc_name)
