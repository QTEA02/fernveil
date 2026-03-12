extends CanvasLayer

var overlay: ColorRect
var panel: PanelContainer
var status_label: Label
var is_open: bool = false

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	overlay.visible = false
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_open:
			close()
			get_viewport().set_input_as_handled()
		elif _can_open():
			open()
			get_viewport().set_input_as_handled()

func _can_open() -> bool:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and dm.is_active:
		return false
	var crafting_ui = get_node_or_null("../CraftingUI")
	if crafting_ui and crafting_ui.is_open:
		return false
	var inventory_ui = get_node_or_null("../InventoryUI")
	if inventory_ui and inventory_ui.is_open:
		return false
	return true

func open() -> void:
	is_open = true
	overlay.visible = true
	panel.visible = true
	_clear_status()
	get_tree().paused = true

func close() -> void:
	is_open = false
	overlay.visible = false
	panel.visible = false
	get_tree().paused = false

func _on_resume() -> void:
	close()

func _on_save() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if sm.save_game():
			_show_status("Game saved!", Color(0.6, 0.9, 0.5))
		else:
			_show_status("Save failed!", Color(0.9, 0.4, 0.4))

func _on_load() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if sm.has_save():
			close()
			sm.load_game()
			_show_status("Game loaded!", Color(0.6, 0.9, 0.5))
		else:
			_show_status("No save file found.", Color(0.9, 0.7, 0.4))

func _on_quit() -> void:
	get_tree().quit()

func _show_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_label.visible = true

func _clear_status() -> void:
	status_label.text = ""
	status_label.visible = false

func _build_ui() -> void:
	# Dark overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Centered panel
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(240, 280)
	panel.offset_left = -120
	panel.offset_top = -140
	panel.offset_right = 120
	panel.offset_bottom = 140

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.13, 0.95)
	style.border_color = Color(0.45, 0.35, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	# Title
	var title = Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Buttons
	var buttons: Array = [
		["Resume", _on_resume],
		["Save Game", _on_save],
		["Load Game", _on_load],
		["Quit", _on_quit],
	]

	for entry in buttons:
		var btn = Button.new()
		btn.text = entry[0]
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(0, 36)

		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.15, 0.13, 0.18, 0.8)
		btn_style.border_color = Color(0.35, 0.3, 0.45)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(8)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
		btn.add_theme_font_size_override("font_size", 15)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.2, 0.32, 0.9)
		hover_style.border_color = Color(0.5, 0.4, 0.65)
		hover_style.set_border_width_all(1)
		hover_style.set_corner_radius_all(4)
		hover_style.set_content_margin_all(8)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(entry[1])
		vbox.add_child(btn)

	# Status label (for save/load feedback)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.visible = false
	vbox.add_child(status_label)

	# Hint
	var hint = Label.new()
	hint.text = "[Esc] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	vbox.add_child(hint)

	panel.add_child(vbox)
	add_child(panel)
