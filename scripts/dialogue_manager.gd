extends Node

signal dialogue_started()
signal dialogue_ended()
signal dialogue_line_shown(speaker: String, text: String)

var is_active: bool = false
var cooldown: float = 0.0
var current_dialogue: Array = []
var current_index: int = 0

# Dialogue data keyed by dialogue ID
# Each dialogue is an Array of lines:
#   { "speaker": "Name", "text": "Hello!", "choices": [...] }
# Choices (optional): [{ "text": "Option A", "next": "dialogue_id" }, ...]
var dialogues: Dictionary = {
	"test_npc": [
		{"speaker": "Stranger", "text": "Hello there, newcomer."},
		{"speaker": "Stranger", "text": "Welcome to Fernveil. This old greenhouse has been waiting for someone."},
		{"speaker": "Stranger", "text": "Take care of the plants, and they might take care of you."},
	],
	"shopkeeper_intro": [
		{"speaker": "Maren", "text": "Oh! You must be the new greenhouse keeper."},
		{"speaker": "Maren", "text": "I run the supply shop in town. If you need seeds or tools, come find me."},
		{"speaker": "Maren", "text": "And if you grow anything interesting... I might be your first customer.", "choices": [
			{"text": "I'll do my best!", "next": "shopkeeper_encourage"},
			{"text": "What counts as interesting?", "next": "shopkeeper_curious"},
		]},
	],
	"shopkeeper_encourage": [
		{"speaker": "Maren", "text": "That's the spirit! Good luck out there."},
	],
	"shopkeeper_curious": [
		{"speaker": "Maren", "text": "Well... some of the plants here aren't exactly normal."},
		{"speaker": "Maren", "text": "You'll see what I mean soon enough."},
	],
}

func _process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta

func start_dialogue(dialogue_id: String) -> void:
	if is_active or cooldown > 0:
		return
	if not dialogues.has(dialogue_id):
		print("[Dialogue] No dialogue found: %s" % dialogue_id)
		return

	current_dialogue = dialogues[dialogue_id]
	current_index = 0
	is_active = true
	get_tree().paused = true
	dialogue_started.emit()
	_show_current_line()

func advance() -> void:
	if not is_active:
		return
	var line = current_dialogue[current_index]
	if line.has("choices") and line["choices"].size() > 0:
		return  # Can't advance past choices — must pick one
	current_index += 1
	if current_index >= current_dialogue.size():
		end_dialogue()
	else:
		_show_current_line()

func select_choice(choice_index: int) -> void:
	if not is_active:
		return
	var line = current_dialogue[current_index]
	if not line.has("choices") or choice_index >= line["choices"].size():
		return
	var choice = line["choices"][choice_index]
	if choice.has("next") and dialogues.has(choice["next"]):
		current_dialogue = dialogues[choice["next"]]
		current_index = 0
		_show_current_line()
	else:
		end_dialogue()

func end_dialogue() -> void:
	is_active = false
	cooldown = 0.2
	get_tree().paused = false
	dialogue_ended.emit()

func _show_current_line() -> void:
	var line = current_dialogue[current_index]
	dialogue_line_shown.emit(line.get("speaker", ""), line.get("text", ""))

func add_dialogue(dialogue_id: String, lines: Array) -> void:
	dialogues[dialogue_id] = lines
