extends CharacterBody2D


const SPEED = 70.0
const JUMP_VELOCITY = -200.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	_set_animation()

func _set_animation():
	$AnimatedSprite2D.play()
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		$AnimatedSprite2D.flip_h = direction > 0
		$AnimatedSprite2D.animation = "walk"
	else: $AnimatedSprite2D.animation = "idle"
	
