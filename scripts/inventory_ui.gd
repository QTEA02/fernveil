extends CanvasLayer

var overlay: ColorRect
var panel: PanelContainer
var item_list: VBoxContainer
var is_open: bool = false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	panel.visible = false

	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		inventory.inventory_changed.connect(_refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	is_open = !is_open
	overlay.visible = is_open
	panel.visible = is_open
	if is_open:
		_refresh()
		get_tree().paused = true
	else:
		get_tree().paused = false

func _refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		return

	var items = inventory.get_all_items()
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		item_list.add_child(empty_label)
		return

	for item_name in items:
		var btn = Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s  x%d" % [item_name, items[item_name]]

		# Style based on whether this is a seed and whether it's selected
		var is_seed = inventory.is_seed(item_name)
		var is_selected = inventory.selected_seed == item_name

		if is_selected:
			# Highlighted as active seed
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.25, 0.35, 0.2, 0.9)
			style.border_color = Color(0.5, 0.8, 0.3)
			style.set_border_width_all(1)
			style.set_corner_radius_all(3)
			style.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7))
			btn.text += "  [SELECTED]"
		elif is_seed:
			# Plantable seed - slightly different look
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.13, 0.18, 0.8)
			style.border_color = Color(0.35, 0.45, 0.3)
			style.set_border_width_all(1)
			style.set_corner_radius_all(3)
			style.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", Color(0.7, 0.85, 0.6))
		else:
			# Non-seed item
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.13, 0.18, 0.6)
			style.set_corner_radius_all(3)
			style.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))

		# Disable Tab focus so it doesn't steal the Tab key
		btn.focus_mode = Control.FOCUS_NONE

		# Hover style for all buttons
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.22, 0.3, 0.9)
		hover_style.set_corner_radius_all(3)
		hover_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("hover", hover_style)

		if is_seed:
			btn.pressed.connect(_on_item_clicked.bind(item_name))
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		item_list.add_child(btn)

func _on_item_clicked(item_name: String) -> void:
	var inventory = get_node_or_null("/root/Inventory")
	if inventory:
		inventory.select_seed(item_name)

		# Update the farm layer's crop column
		var col = inventory.get_seed_column()
		var farm_layer = get_node_or_null("/root/world/FarmLayer")
		if farm_layer and col >= 0:
			farm_layer.crop_column = col

		_refresh()

func _build_ui() -> void:
	# Dark overlay behind panel
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Centered panel
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 350)
	panel.offset_left = -150
	panel.offset_top = -175
	panel.offset_right = 150
	panel.offset_bottom = 175

	# Style the panel background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.15, 0.95)
	style.border_color = Color(0.4, 0.35, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Title
	var title = Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	vbox.add_child(title)

	# Separator line
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Hint for seeds
	var seed_hint = Label.new()
	seed_hint.text = "Click a seed to select it for planting"
	seed_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seed_hint.add_theme_font_size_override("font_size", 11)
	seed_hint.add_theme_color_override("font_color", Color(0.5, 0.6, 0.45))
	vbox.add_child(seed_hint)

	# Scrollable item list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 4)

	scroll.add_child(item_list)
	vbox.add_child(scroll)

	# Close hint
	var hint = Label.new()
	hint.text = "[Tab] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint)

	panel.add_child(vbox)
	add_child(panel)
