extends CanvasLayer

var panel: PanelContainer
var speaker_label: Label
var text_label: RichTextLabel
var choices_container: VBoxContainer
var continue_hint: Label

var full_text: String = ""
var visible_chars: int = 0
var chars_per_second: float = 40.0
var char_timer: float = 0.0
var is_typing: bool = false

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	panel.visible = false

	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.dialogue_started.connect(_on_dialogue_started)
		dm.dialogue_ended.connect(_on_dialogue_ended)
		dm.dialogue_line_shown.connect(_on_line_shown)

func _unhandled_input(event: InputEvent) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if not dm or not dm.is_active:
		return

	if event.is_action_pressed("interact"):
		if is_typing:
			# Skip typewriter, show full text
			is_typing = false
			text_label.visible_characters = -1
			_update_continue_hint()
		else:
			dm.advance()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_typing:
		char_timer += delta * chars_per_second
		while char_timer >= 1.0 and visible_chars < full_text.length():
			visible_chars += 1
			char_timer -= 1.0
			text_label.visible_characters = visible_chars
		if visible_chars >= full_text.length():
			is_typing = false
			text_label.visible_characters = -1
			_update_continue_hint()

func _on_dialogue_started() -> void:
	panel.visible = true

func _on_dialogue_ended() -> void:
	panel.visible = false

func _on_line_shown(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	full_text = text
	text_label.text = text
	visible_chars = 0
	char_timer = 0.0
	is_typing = true
	text_label.visible_characters = 0

	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()

	continue_hint.visible = false

	# Check if current line has choices
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and dm.is_active:
		var line = dm.current_dialogue[dm.current_index]
		if line.has("choices") and line["choices"].size() > 0:
			# Show choices after typing finishes — handled in _update_continue_hint
			pass

func _update_continue_hint() -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if not dm or not dm.is_active:
		return

	var line = dm.current_dialogue[dm.current_index]
	if line.has("choices") and line["choices"].size() > 0:
		_show_choices(line["choices"])
		continue_hint.visible = false
	else:
		continue_hint.visible = true

func _show_choices(choices: Array) -> void:
	for i in choices.size():
		var btn = Button.new()
		btn.text = choices[i]["text"]
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.13, 0.18, 0.8)
		style.border_color = Color(0.4, 0.5, 0.35)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color(0.8, 0.9, 0.7))

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.3, 0.2, 0.9)
		hover_style.border_color = Color(0.5, 0.7, 0.4)
		hover_style.set_border_width_all(1)
		hover_style.set_corner_radius_all(3)
		hover_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)

func _on_choice_selected(index: int) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.select_choice(index)

func _build_ui() -> void:
	# Bottom-anchored dialogue panel
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -140
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_bottom = -20

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 0.95)
	style.border_color = Color(0.4, 0.35, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Speaker name
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 16)
	speaker_label.add_theme_color_override("font_color", Color(1, 0.85, 0.6))
	vbox.add_child(speaker_label)

	# Dialogue text
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size", 14)
	text_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.85))
	vbox.add_child(text_label)

	# Choices container
	choices_container = VBoxContainer.new()
	choices_container.add_theme_constant_override("separation", 4)
	vbox.add_child(choices_container)

	# Continue hint
	continue_hint = Label.new()
	continue_hint.text = "[E] Continue"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 11)
	continue_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	continue_hint.visible = false
	vbox.add_child(continue_hint)

	panel.add_child(vbox)
	add_child(panel)
