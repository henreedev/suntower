extends RigidBody2D
class_name FlowerHead

enum State {INACTIVE, EXTENDING, RETRACTING}

const ROTATE_SPEED = PI 
const EXTEND_SPEED = 90.0
const GRAVITY = -0.2
const vine_root_offset := Vector2(0, 5)

@export var vine_seg : PackedScene
@export var max_extended_len := 10000.0
const BASE_MAX_EXTENDED_LEN := 10000.0

var _has_sun_buff := false
var _state : State = State.INACTIVE
var base_segments := 15
var _segs := 15
var _set_transform 
var _target_angle : float
var _len_per_seg : float
var _extending_dist_travelled := 0.0
var _extended_len := 0.0
var _root_seg : Vine
var _first_seg : Vine
var _retracting_seg : Vine

@onready var _last_pos : Vector2 = position

@onready var vine_line : Line2D = $Vines/Line2D
@onready var vine_creator : Vine = vine_seg.instantiate()
@onready var stuck_timer : Timer = $StuckTimer
@onready var _player : Player2 = get_tree().get_first_node_in_group("player2")

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_vine()
	add_collision_exception_with(_player)

func _process(delta):
	act_on_state()
	_draw_line()
	_root_seg.make_self_exception()

func _connect_sunrays():
	for sunrays in get_tree().get_nodes_in_group("sunrays"):
		sunrays.connect("sun_hit", _on_sunrays_hit)

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
	var adj := 1.5
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
			begin_retracting()
	elif _state == State.RETRACTING:
		lock_rotation = true
		if _segs <= base_segments:
			begin_inactive()
	elif _state == State.INACTIVE:
		begin_inactive()

func begin_extending():
	if _state == State.INACTIVE:
		_state = State.EXTENDING
		$SpikedHitbox.disabled = false
		get_tree().call_group("vine", "set_grav", 0.1)
		stuck_timer.stop()
		_player.gravity_scale = 1.0
		_player.linear_damp = 0.0
		_has_sun_buff = false

func begin_inactive():
	_state = State.INACTIVE
	physics_material_override.friction = 0.0
	$SpikedHitbox.disabled = true
	$AnimatedSprite2D.animation = "normal"
	$Sparkles.emitting = false
	gravity_scale = GRAVITY
	lock_rotation = false
	#create_tween().tween_property(self, "rotation", 0, 0.2).set_ease(Tween.EASE_IN_OUT)
	get_tree().call_group("vine", "set_grav", 0.03)
	stuck_timer.stop()
	_player.gravity_scale = 1.0
	_player.linear_damp = 0.0

func begin_retracting():
	_state = State.RETRACTING
	#var child : Vine = _root_seg.get_child_seg()
	#_root_seg.get_node("PinJoint2D").node_b = ""
	#var new_pos = _root_seg.position + Vector2(0, _len_per_seg / 2).rotated(global_rotation)
	#child.position = new_pos
	#child._set_pos = new_pos
	#_root_seg.get_node("PinJoint2D").node_b = child.get_path()
	get_tree().call_group("vine", "set_grav", 0.5)
	create_tween().tween_property($RootVinePin, "position", Vector2(0, 0), 0.5)
	max_extended_len = BASE_MAX_EXTENDED_LEN # Remove sunlight bonuses
	physics_material_override.friction = 1.0
	stuck_timer.start()
	_player.gravity_scale = 0.3
	_player.linear_damp = 50.0

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
	elif _state == State.RETRACTING:
		var dir = Vector2(0.0, 0.0)
		if Input.is_action_pressed("move_left"):
			dir += Vector2(-1.0, 0.0)
		if Input.is_action_pressed("move_right"):
			dir += Vector2(1.0, 0.0)
		if Input.is_action_pressed("move_up"):
			dir += Vector2(0.0, -1.0)
		if Input.is_action_pressed("move_down"):
			dir += Vector2(0.0, 1.0)
		dir = dir.normalized()
		const MOVE_STRENGTH = 115.0
		_player.apply_central_force(dir.rotated(_player.position.angle_to_point(position) + PI / 2) * MOVE_STRENGTH) 
	_fix_gap(state)

func _display_sun_buff():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2), 0.5)
	tween.tween_property(self, "modulate", Color(1., 1., 1.), 0.5)

func _physics_process(delta):
	var pos = position
	match _state:
		State.EXTENDING:
			if _has_sun_buff and max_extended_len != BASE_MAX_EXTENDED_LEN:
				const buff = 50.0
				max_extended_len += buff
				_display_sun_buff()
			_extending_dist_travelled += _last_pos.distance_to(pos)
			if _extending_dist_travelled > _len_per_seg:
				_add_seg()
				_extended_len += _len_per_seg
				_extending_dist_travelled -= _len_per_seg
			if _extended_len > max_extended_len:
				begin_retracting()
		State.RETRACTING:
			if not _retracting_seg:
				# Detach node near root, and propel it towards root
				_retracting_seg = _root_seg.get_child_seg()
				_root_seg.get_node("PinJoint2D").softness = 0.0
				_root_seg.get_node("PinJoint2D").node_b = ""
				_root_seg.detached_child = _retracting_seg
			var retract_dir = _retracting_seg.position.direction_to(_root_seg.position)
			const FORCE_STRENGTH = 125.0
			var force = retract_dir * FORCE_STRENGTH
			_retracting_seg.apply_central_force(force)
			_retracting_seg.get_child_seg().apply_central_force(force)
			_retracting_seg.get_child_seg().get_child_seg().apply_central_force(force)
			_root_seg.apply_central_force(retract_dir.rotated(PI) * FORCE_STRENGTH)
			const MIN_DIST = 6
			if _retracting_seg.position.distance_to(_root_seg.position) < MIN_DIST:
				_retracting_seg.queue_free()
				_root_seg.get_node("PinJoint2D").node_b = _retracting_seg.get_child_seg().get_path()
				_root_seg.get_node("PinJoint2D").softness = 0.0
				_segs -= 1
				_retracting_seg = null
				_root_seg.detached_child = null
				stuck_timer.start()
		State.INACTIVE:
			pass
	_last_pos = pos

func _fix_gap(state):
	if _state == State.INACTIVE or _state == State.EXTENDING:
		const MAX_GAP = 3.0
		var child : Vine = _root_seg.get_child_seg()
		var gap : Vector2 = _root_seg.position - child.position
		if gap.length() > MAX_GAP:
			_root_seg.get_node("PinJoint2D").node_b = ""
			child.position += gap / 0.75
			child._set_pos = child.position
			_root_seg.set_child(child)

func _add_seg():
	var child : Vine = _root_seg.get_child_seg()
	
	var new_child : Vine = vine_creator.create(child)
	$Vines.add_child(new_child)
	new_child.make_self_exception()
	new_child.add_collision_exception_with(child)
	new_child.position = child.position
	new_child.rotation = child.rotation
	
	child.position = child.position + Vector2(0, _len_per_seg / 3).rotated(global_rotation)
	child._set_pos = child.position
	child.rotation = global_rotation

	_root_seg.get_node("PinJoint2D").node_b = new_child.get_path()
	_segs += 1

func _on_bg_music_finished():
	$Sound/BGMusic.play()

func _on_sunrays_hit():
	_has_sun_buff = true
	print("received sun_hit")

func _on_stuck_timer_timeout():
	#var unstuck_vec = Vector2(randf_range(-5, 5), randf_range(-5, 5))
	#if _retracting_seg:
		#_retracting_seg._set_pos = _retracting_seg.position + unstuck_vec
	pass

