extends RigidBody2D


const SPEED = 70.0
const JUMP_VELOCITY = -200.0
var _grounded = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(delta):
	# Set the animation based on input.
	_set_animation()

func _physics_process(delta):
	# Handle jump.
	if Input.is_action_just_pressed("jump") and _grounded:
		set_axis_velocity(Vector2(0, JUMP_VELOCITY))

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction and _grounded:
		var slide_frame = $AnimatedSprite2D.frame == 2 or $AnimatedSprite2D.frame == 3
		var walking = $AnimatedSprite2D.animation == "walk"
		if walking and slide_frame:
			set_axis_velocity(Vector2(direction * SPEED * 1.8, 0))
		else: set_axis_velocity(Vector2(direction * SPEED * 0.35, 0))

func _integrate_forces(state):
	if _grounded:
		const rotate_speed = 10.0
		#var lerp_angle(rotation, 0, rotate_speed * state.step)
		state.transform = Transform2D(0, position)
		set_deferred("lock_rotation", true)
	else:
		set_deferred("lock_rotation", false)

func _set_animation():
	$AnimatedSprite2D.play()
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		$AnimatedSprite2D.flip_h = direction > 0
		$AnimatedSprite2D.animation = "walk"
	else: $AnimatedSprite2D.animation = "idle"
	


func _on_grounded_body_entered(body):
	if body.is_in_group("tower"):
		_grounded = true




func _on_grounded_body_exited(body):
	if body.is_in_group("tower"):
		_grounded = false
