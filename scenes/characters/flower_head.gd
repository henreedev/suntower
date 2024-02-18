extends RigidBody2D
class_name FlowerHead

enum State {INACTIVE, EXTENDING, RETRACTING}

const ROTATE_SPEED = PI 
const EXTEND_SPEED = 125.0
const GRAVITY = -0.2
const vine_root_offset := Vector2(0, 5)

@export var vine_seg : PackedScene
@export var max_extended_len := 50.0

var _state : State = State.INACTIVE
var base_segments := 20
var _segs := 20
var extend_segments := 18
var _set_transform 
var _target_angle : float
var _len_per_seg : float
var _extending_dist_travelled := 0.0
var _extended_len := 0.0
var _root_seg : Vine
var _first_seg : Vine

@onready var _last_pos : Vector2 = position

@onready var vine_line : Line2D = $Vines/Line2D
@onready var vine_creator : Vine = vine_seg.instantiate()

@onready var _player : Player2 = get_tree().get_first_node_in_group("player2")

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_vine()

func _process(delta):
	act_on_state()
	_draw_line()

func _draw_line():
	vine_line.clear_points()
	var vine_seg : Vine = _root_seg
	vine_line.add_point($RootVinePin.global_position)
	while(vine_seg):
		vine_line.add_point(vine_seg.position)
		vine_seg = vine_seg.get_child_seg() if not vine_seg.get_child_seg() is Player2 else null

func _spawn_vine():
	var first_vine_pos = _player.position + _player.vine_root_offset
	var final_vine_pos = position + vine_root_offset 
	var diff = final_vine_pos - first_vine_pos
	var adj := 2
	_len_per_seg = diff.length() / base_segments * adj
	var curr_seg : Vine = null
	var last_seg : Vine = null
	 
	# Make vine segments from the pot to the flower, pinning them to each other.
	# Connect the last segment to the flower.
	for i in base_segments:
		if i == 0:
			curr_seg = vine_creator.create(_player)
			_first_seg = curr_seg
			#curr_seg.lock_rotation = true
			#curr_seg.set_rotation_match(_player)
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
			_root_seg = curr_seg
			#curr_seg.lock_rotation = true
			#curr_seg.set_rotation_match(self)
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
	var pos = state.transform.get_origin()
	var rot = state.transform.get_rotation()
	if _set_transform:
		state.transform = _set_transform
		_set_transform = null
	if _state == State.EXTENDING:
		_target_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
		state.transform = Transform2D(lerp_angle(state.transform.get_rotation(), _target_angle, state.step * ROTATE_SPEED), state.transform.get_origin()) 
		state.angular_velocity = 0
		state.linear_velocity = Vector2(0, -EXTEND_SPEED).rotated(rotation)

func _physics_process(delta):
	var pos = position
	match _state:
		State.EXTENDING:
			_extending_dist_travelled += _last_pos.distance_to(pos)
			if _extending_dist_travelled > _len_per_seg:
				# Add a segment after the root 
				#call_deferred("_add_seg")
				_add_seg()
				_segs += 1
				_extended_len += _len_per_seg
				_extending_dist_travelled -= _len_per_seg
			if _extended_len > max_extended_len:
				_state = State.RETRACTING
		State.RETRACTING:
			pass
		State.INACTIVE:
			pass
	_last_pos = pos
	# Testing
	#if Input.is_action_just_pressed("jump"):
		#_add_seg()

func _add_seg():
	var child : Vine = _root_seg.get_child_seg()
	var new_child : Vine = vine_creator.create(child)
	$Vines.add_child(new_child)
	new_child.make_self_exception()
	new_child.add_collision_exception_with(child)
	new_child.position = child.position
	new_child.rotation = child.rotation

	#print(_root_seg.position)
	child.position = child.position + Vector2(0, _len_per_seg).rotated(global_rotation)
	child._set_pos = child.position
	child.rotation = global_rotation
	#print(new_child.position)
	#print(child.position)
	#new_child.get_node("PinJoint2D").node_b = child.get_path()
	_root_seg.get_node("PinJoint2D").node_b = new_child.get_path()
	#_root_seg.set_child(new_child)
	_segs += 1

func _on_bg_music_finished():
	$Sound/BGMusic.play()

