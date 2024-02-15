extends RigidBody2D
class_name FlowerHead

enum State {INACTIVE, EXTENDING, RETRACTING}

const ROTATE_SPEED = PI 
const EXTEND_SPEED = 50.0
const GRAVITY = 0.1

var _state : State = State.INACTIVE
var base_segments := 8
var extend_segments := 18
var _set_transform 
var _target_angle : float
var _segs := 8


@onready var _player : Player2 = get_tree().get_first_node_in_group("player2")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	act_on_state()

func act_on_state():
	if _state == State.EXTENDING:
		lock_rotation = false
		gravity_scale = 0.0
		_target_angle = get_angle_to(get_global_mouse_position() - global_position)
		print(_target_angle)
		print(get_global_mouse_position())
		if Input.is_action_just_released("extend"):
			# switch state
			_state = State.RETRACTING
	elif _state == State.RETRACTING:
		lock_rotation = true
		if _segs == base_segments:
			_state = State.INACTIVE
	elif _state == State.INACTIVE:
		$SpikedHitbox.disabled = true
		$NormalHitbox.disabled = false
		gravity_scale = GRAVITY
		lock_rotation = false

func begin_extending():
	if _state == State.INACTIVE:
		_state = State.EXTENDING
		$SpikedHitbox.disabled = false
		$NormalHitbox.disabled = true
		

func _integrate_forces(state):
	if _set_transform:
		state.transform = _set_transform
		_set_transform = null
	if _state == State.EXTENDING:
		var rotation_adj = rotate_toward(rotation, _target_angle, state.step * ROTATE_SPEED)
		var rot_dir = 1 if rotation_adj < rotation else -1
		state.angular_velocity = rot_dir * ROTATE_SPEED
		state.linear_velocity = Vector2(EXTEND_SPEED, 0).rotated(rotation_adj)
