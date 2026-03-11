extends CharacterBody2D

@export var speed: float = 100.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea

var last_direction: String = "down"

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
		update_animation(input_vector, true)
	else:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO, false)

	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		# Don't interact if a UI is open
		if get_tree().paused:
			return

		# First check Area2D interactables (mushrooms, crafting stations, etc.)
		var areas := interact_area.get_overlapping_areas()
		if areas.size() > 0:
			var closest := areas[0]
			if closest.has_method("interact"):
				closest.interact()
				return

		# Then check the farm layer for plantable tiles
		var farm_layer := get_node_or_null("../FarmLayer")
		if farm_layer and farm_layer.has_method("interact_at"):
			farm_layer.interact_at(global_position)

func update_animation(direction: Vector2, is_moving: bool) -> void:
	var anim_direction := last_direction

	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				anim_direction = "right"
				last_direction = "right"
				animated_sprite.flip_h = false
			else:
				anim_direction = "right"
				last_direction = "left"
				animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
			if direction.y > 0:
				anim_direction = "down"
				last_direction = "down"
			else:
				anim_direction = "up"
				last_direction = "up"
	else:
		if last_direction == "left":
			anim_direction = "right"
			animated_sprite.flip_h = true
		elif last_direction == "right":
			anim_direction = "right"
			animated_sprite.flip_h = false
		else:
			anim_direction = last_direction
			animated_sprite.flip_h = false

	if is_moving:
		animated_sprite.play("walk_" + anim_direction)
	else:
		animated_sprite.play("idle_" + anim_direction)