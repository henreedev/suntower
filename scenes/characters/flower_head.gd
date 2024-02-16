extends RigidBody2D
class_name FlowerHead

enum State {INACTIVE, EXTENDING, RETRACTING}

const ROTATE_SPEED = PI 
const EXTEND_SPEED = 125.0
const GRAVITY = -0.2
const vine_root_offset := Vector2(0, 6)

var _state : State = State.INACTIVE
var base_segments := 30
var _segs := 30
var extend_segments := 18
var _set_transform 
var _target_angle : float

@export var vine_seg : PackedScene

@onready var vine_creator : Vine = vine_seg.instantiate()

@onready var _player : Player2 = get_tree().get_first_node_in_group("player2")

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_vine()

func _process(delta):
	act_on_state()

func _spawn_vine():
	var first_vine_pos = _player.position + _player.vine_root_offset
	var final_vine_pos = position + vine_root_offset 
	var diff = final_vine_pos - first_vine_pos
	var curr_seg : Vine = null
	var last_seg : Vine = null
	 
	# Make vine segments from the pot to the flower, pinning them to each other.
	# Connect the last segment to the flower.
	for i in base_segments:
		if i == 0:
			curr_seg = vine_creator.create(_player)
		else:
			curr_seg = vine_creator.create(last_seg)
		var progress = diff * float(i) / base_segments
		var seg_pos = first_vine_pos + progress
		$Vines.add_child(curr_seg)
		curr_seg.make_self_exception()
		curr_seg.position = seg_pos
		print(seg_pos)
		if i == 0:
			curr_seg.set_child(_player)
		if i == base_segments - 1:
			$RootVinePin.node_b = curr_seg.get_path()
		last_seg = curr_seg
	

func act_on_state():
	if _state == State.EXTENDING:
		$AnimatedSprite2D.animation = "spiked"
		$Sparkles.emitting = true
		lock_rotation = false
		gravity_scale = 0.0
		if Input.is_action_just_released("extend"):
			_state = State.RETRACTING
	elif _state == State.RETRACTING:
		lock_rotation = true
		if _segs == base_segments:
			_state = State.INACTIVE
	elif _state == State.INACTIVE:
		$SpikedHitbox.disabled = true
		$AnimatedSprite2D.animation = "normal"
		$Sparkles.emitting = false
		gravity_scale = GRAVITY
		lock_rotation = false

func begin_extending():
	if _state == State.INACTIVE:
		_state = State.EXTENDING
		$SpikedHitbox.disabled = false

func _integrate_forces(state):
	if _set_transform:
		state.transform = _set_transform
		_set_transform = null
	if _state == State.EXTENDING:
		_target_angle = state.transform.get_origin().angle_to_point(get_global_mouse_position()) + PI/2
		state.transform = Transform2D(lerp_angle(state.transform.get_rotation(), _target_angle, state.step * ROTATE_SPEED), state.transform.get_origin()) 
		state.angular_velocity = 0
		state.linear_velocity = Vector2(0, -EXTEND_SPEED).rotated(rotation)
