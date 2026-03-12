extends CanvasLayer

var overlay: ColorRect
var panel: PanelContainer
var recipe_list: VBoxContainer
var title_label: Label
var is_open: bool = false
var current_station: String = ""

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	overlay.visible = false
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		close()
		get_viewport().set_input_as_handled()

func open(station_type: String) -> void:
	current_station = station_type
	is_open = true
	overlay.visible = true
	panel.visible = true
	title_label.text = station_type
	_refresh()
	get_tree().paused = true

func close() -> void:
	is_open = false
	overlay.visible = false
	panel.visible = false
	get_tree().paused = false

func _refresh() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

	var crafting = get_node_or_null("/root/CraftingRecipes")
	if not crafting:
		return

	var recipes = crafting.get_recipes_for_station(current_station)
	if recipes.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No recipes available"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		recipe_list.add_child(empty_label)
		return

	for recipe in recipes:
		var can_make = crafting.can_craft(recipe)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# Craft button
		var btn = Button.new()
		btn.text = "Craft"
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(60, 0)
		if can_make:
			btn.pressed.connect(_on_craft.bind(recipe))
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			btn.disabled = true

		var btn_style = StyleBoxFlat.new()
		if can_make:
			btn_style.bg_color = Color(0.2, 0.35, 0.2, 0.9)
			btn_style.border_color = Color(0.4, 0.7, 0.3)
		else:
			btn_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
			btn_style.border_color = Color(0.3, 0.3, 0.3)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(3)
		btn_style.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", btn_style)

		if can_make:
			btn.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7))
		else:
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		hbox.add_child(btn)

		# Recipe info
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var result_label = Label.new()
		var result_text = recipe["result"]
		if recipe["result_count"] > 1:
			result_text += " x%d" % recipe["result_count"]
		result_label.text = result_text
		if can_make:
			result_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		else:
			result_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55))
		info.add_child(result_label)

		# Ingredients list
		var ingredients_text = ""
		var inventory = get_node_or_null("/root/Inventory")
		for item_name in recipe["ingredients"]:
			var needed: int = recipe["ingredients"][item_name]
			var have: int = 0
			if inventory:
				have = inventory.get_item_count(item_name)
			if ingredients_text != "":
				ingredients_text += ", "
			var color_tag = "aaffaa" if have >= needed else "ff8888"
			ingredients_text += "%s [color=#%s]%d/%d[/color]" % [item_name, color_tag, have, needed]

		var ing_label = RichTextLabel.new()
		ing_label.bbcode_enabled = true
		ing_label.text = ingredients_text
		ing_label.fit_content = true
		ing_label.scroll_active = false
		ing_label.custom_minimum_size = Vector2(0, 20)
		ing_label.add_theme_font_size_override("normal_font_size", 12)
		info.add_child(ing_label)

		hbox.add_child(info)

		# Container style
		var row_panel = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		row_style.bg_color = Color(0.12, 0.1, 0.15, 0.6)
		row_style.set_corner_radius_all(3)
		row_style.set_content_margin_all(6)
		row_panel.add_theme_stylebox_override("panel", row_style)
		row_panel.add_child(hbox)

		recipe_list.add_child(row_panel)

func _on_craft(recipe: Dictionary) -> void:
	var crafting = get_node_or_null("/root/CraftingRecipes")
	if crafting:
		crafting.craft(recipe)
		_refresh()

func _build_ui() -> void:
	# Dark overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Centered panel
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 400)
	panel.offset_left = -190
	panel.offset_top = -200
	panel.offset_right = 190
	panel.offset_bottom = 200

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.15, 0.95)
	style.border_color = Color(0.5, 0.4, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Title
	title_label = Label.new()
	title_label.text = "Crafting"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	vbox.add_child(title_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Scrollable recipe list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	recipe_list = VBoxContainer.new()
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("separation", 6)

	scroll.add_child(recipe_list)
	vbox.add_child(scroll)

	# Close hint
	var hint = Label.new()
	hint.text = "[E] or [Esc] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint)

	panel.add_child(vbox)
	add_child(panel)
