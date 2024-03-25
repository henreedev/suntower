extends RigidBody2D
class_name FlowerHead

enum State {INACTIVE, EXTENDING, RETRACTING}

const ROTATE_SPEED = PI 
const GRAVITY = -0.2
const vine_root_offset := Vector2(0, 5)

@export var vine_seg : PackedScene
@export var play_animation_on_start := false
@export var max_extended_len := 125.0
const BASE_MAX_EXTENDED_LEN := 125.0
const EXTEND_SPEED = 90.0
var extend_speed_mod = 1.0
var extra_len = 0.0
var extra_len_display = 0.0
var vine_len_display = BASE_MAX_EXTENDED_LEN
#const EXTEND_SPEED = 200.0
#@export var max_extended_len := 5000.0
#const BASE_MAX_EXTENDED_LEN := 5000.0

var initial_flower_pos := Vector2(0, -44)
var initial_pot_pos := Vector2(0, 6)


var _animating = false

var _has_sun_buff := false
var _sun_buff_applied := false
var _has_lightning_buff := false

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
var can_extend := true
var _can_nudge = false
var sun_buff_tween : Tween

@onready var _last_pos : Vector2 = position

@onready var vine_line : Line2D = $Vines/Line2D
@onready var vine_creator : Vine = vine_seg.instantiate()
@onready var stuck_timer : Timer = $StuckTimer
@onready var _player : Player2 = get_tree().get_first_node_in_group("player2")
@onready var _bar : TextureProgressBar = get_tree().get_first_node_in_group("hud")
@onready var _sprite : AnimatedSprite2D = $Sprite2D
@onready var tower : Tower = get_tree().get_first_node_in_group("tower")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_volume()
	_spawn_vine()
	add_collision_exception_with(_player)
	if play_animation_on_start:
		_animating = true
	begin_inactive()
	if play_animation_on_start:
		play_spawn_animation()
	else:
		no_cutscene_setup()

func no_cutscene_setup():
	$Sound/BGMusic.play()
	get_tree().get_first_node_in_group("stopwatch").start()
	create_tween().tween_property($Camera2D,"zoom", Vector2(3.0, 3.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($Camera2D, "offset", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(0.5).timeout
	create_tween().tween_property(get_tree().get_first_node_in_group("ui"), "offset", Vector2(0, 0), 1.0).set_trans(Tween.TRANS_CUBIC)
	

func _process(delta):
	_draw_line()
	_root_seg.make_self_exception()
	if not _animating:
		act_on_state()



func play_spawn_animation():
	# Make vines and line invisible, tween fade them in
	get_tree().set_group("vine", "modulate", Color(1.0, 1.0, 1.0, 0.0))
	get_tree().set_group("vine", "linear_damp", 100.0)
	$Vines/Line2D.modulate = Color(1.0,1.0,1.0,0.0)
	$Sprite2D.modulate = Color(1.0,1.0,1.0,0.0)
	$Camera2D.offset = Vector2(0, 6)
	$Camera2D.zoom = Vector2(15, 15)
	create_tween().tween_property($Camera2D,"zoom", Vector2(5.95, 5.95), 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($Camera2D,"offset", Vector2(0, 4), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	await get_tree().create_timer(2.0).timeout
	$Sound/BGMusic.play()
	
	
	#create_tween().tween_property($Camera2D, "zoom", Vector2(6.0, 6.0), 2.0).set_trans(Tween.TRANS_SINE) 
	var offset_tween = create_tween()
	offset_tween.tween_property($Camera2D, "offset", Vector2(-80, 4), 1.5).from(Vector2(0, 4)).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	offset_tween.tween_property($Camera2D, "offset", Vector2(80, 4), 2.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	offset_tween.tween_property($Camera2D, "offset", Vector2(0, 4), 2.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	# 7 seconds of camera panning 
	await get_tree().create_timer(6.7).timeout
	var delay = 1.95
	var i = -1
	for vine in get_tree().get_nodes_in_group("vine"):
		i = i + 1
		await get_tree().create_timer(delay * 1.0 / (i+3)).timeout
		var tween = create_tween().set_parallel(true)
		tween.tween_property(vine, "modulate", Color(1.0,1.0,1.0,1.0), 0.5)
		var sprite_scale = Vector2(1.0, 1.4)
		tween.tween_property(vine, "sprite_scale", sprite_scale, 0.5).from(Vector2(1.0, 0.0)).set_ease(Tween.EASE_IN_OUT)
	for vine in get_tree().get_nodes_in_group("vine"):
		create_tween().tween_property(vine, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	create_tween().tween_property($Vines/Line2D, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	create_tween().tween_property($Sprite2D, "scale", Vector2(1.0, 1.0), 0.4).from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property($Sprite2D, "offset", Vector2(0.0, 0.0), 0.4).from(Vector2(0, 5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property($Sprite2D, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	get_tree().set_group("vine", "sprite_scale", Vector2(1.0, 0.5))
	# Finish animation
	create_tween().tween_property($Camera2D,"zoom", Vector2(3.0, 3.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($Camera2D, "offset", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(0.5).timeout
	create_tween().tween_property(get_tree().get_first_node_in_group("ui"), "offset", Vector2(0, 0), 1.0).set_trans(Tween.TRANS_CUBIC)
	_animating = false
	get_tree().get_first_node_in_group("stopwatch").start()
	get_tree().set_group("vine", "linear_damp", 1.0)

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
		last_seg = curr_seg

func act_on_state():
	if _state == State.EXTENDING:
		if Input.is_action_just_released("extend") and not _animating:
			begin_retracting()
	elif _state == State.RETRACTING:
		lock_rotation = true
		if _segs <= base_segments:
			begin_inactive()
	elif _state == State.INACTIVE:
		pass

func begin_extending():
	if _state == State.INACTIVE and can_extend and not _animating:
		_state = State.EXTENDING
		_sprite.animation = "spiked"
		_sprite.play()
		$Sparkles.emitting = true
		lock_rotation = false
		collision_mask = 13
		$SpikedHitbox.disabled = false
		get_tree().call_group("vine", "set_grav", 0.1)
		stuck_timer.stop()
		_player.gravity_scale = 1.0
		_player.linear_damp = 0.0
		linear_damp = 0.0
		_player.mass = 0.25
		extend_speed_mod = 0.3
		create_tween().tween_property(self, "extend_speed_mod", 1.0, 0.3)

func begin_inactive():
	_sprite.animation = "retract"
	_sprite.frame = 0
	_sprite.play()
	_has_sun_buff = false
	_sun_buff_applied = false
	if sun_buff_tween:
		sun_buff_tween.kill()
	sun_buff_tween = create_tween()
	sun_buff_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.6)
	collision_mask = 9
	_state = State.INACTIVE
	max_extended_len = BASE_MAX_EXTENDED_LEN # Remove sunlight bonuses
	_extended_len = 0.0
	extra_len = 0.0
	extra_len_display = 0.0
	vine_len_display = BASE_MAX_EXTENDED_LEN
	physics_material_override.friction = 0.0
	$SpikedHitbox.disabled = true
	$Sparkles.emitting = false
	$Sparkles.amount = 5
	gravity_scale = GRAVITY
	lock_rotation = false
	get_tree().call_group("vine", "set_grav", 0.03)
	stuck_timer.stop()
	_player.gravity_scale = 1.0
	_player.linear_damp = 0.0
	_player.mass = 1.0
	linear_damp = 1.0

func begin_retracting():
	_state = State.RETRACTING
	get_tree().call_group("vine", "set_grav", 0.5)
	create_tween().tween_property($RootVinePin, "position", Vector2(0, 0), 0.5)
	physics_material_override.friction = 1.0
	stuck_timer.start()
	_player.gravity_scale = 0.3
	#_player.linear_damp = 500.0
	linear_damp = 10.0
	gravity_scale = 0.2
	_extending_dist_travelled = 0
	_extended_len = 0

func _integrate_forces(state):
	if not _animating:
		var pos = state.transform.get_origin()
		var rot = state.transform.get_rotation()
		if _set_transform:
			state.transform = _set_transform
			_set_transform = null
		if _state == State.EXTENDING:
			_target_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
			state.transform = Transform2D(lerp_angle(state.transform.get_rotation(), _target_angle, state.step * ROTATE_SPEED), state.transform.get_origin()) 
			state.angular_velocity = 0
			state.linear_velocity = Vector2(0, -EXTEND_SPEED * extend_speed_mod).rotated(rotation)
		elif _state == State.RETRACTING:
			var dir = Vector2(0.0, 0.0)
			if Input.is_action_pressed("move_left") and not _animating:
				dir += Vector2(-1.0, 0.0)
			if Input.is_action_pressed("move_right") and not _animating:
				dir += Vector2(1.0, 0.0)
			dir = dir.normalized()
			const MOVE_STRENGTH = 105.0
			_player.apply_central_force(dir * MOVE_STRENGTH)
		elif _state == State.INACTIVE:
			var mouse_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
			const STR = 4.0
			state.transform = Transform2D(lerp_angle(rotation, mouse_angle, STR * state.step), state.transform.get_origin())
			const STR2 = 20.0
			var force_toward_mouse = Vector2(0, -1).rotated(mouse_angle) * STR2
			apply_central_force(force_toward_mouse)
		_fix_gap(state)

func _display_sun_buff():
	if sun_buff_tween:
		sun_buff_tween.kill()
	sun_buff_tween = create_tween()
	var tween_2 = create_tween()
	sun_buff_tween.tween_property(self, "modulate", Color(4, 4, 4), 0.5)
	tween_2.tween_property(_bar, "tint_progress", Color(2, 2, 2), 0.5)
	sun_buff_tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 1.5)
	tween_2.tween_property(_bar, "tint_progress", Color(1., 1., 1.), 0.5)
	$Sparkles.emitting = true
	$Sparkles.amount = 125

func _physics_process(delta):
	if not _animating:
		can_extend = _player.touching and _player.linear_velocity.length_squared() < 2.0
		var pos = position
		match _state:
			State.EXTENDING:
				if _has_sun_buff and not _sun_buff_applied:
					extra_len = BASE_MAX_EXTENDED_LEN
					extra_len_display = BASE_MAX_EXTENDED_LEN
					_sun_buff_applied = true
					_display_sun_buff()
				_extending_dist_travelled += _last_pos.distance_to(pos)
				if _extending_dist_travelled > _len_per_seg:
					_add_seg()
					_extended_len += _len_per_seg
					_extending_dist_travelled -= _len_per_seg
					if extra_len and extra_len_display:
						extra_len_display -= _len_per_seg
						if extra_len_display < 0.0: extra_len_display = 0.0
					else: vine_len_display -= _len_per_seg
				if _extended_len > max_extended_len + extra_len:
					begin_retracting()
			State.RETRACTING:
				if _segs <= base_segments:
					begin_inactive()
				else:
					if not _retracting_seg:
						# Detach node near root, and propel it towards root
						_retracting_seg = _root_seg.get_child_seg()
						_root_seg.get_node("PinJoint2D").softness = 0.0
						_root_seg.get_node("PinJoint2D").node_b = ""
						_root_seg.detached_child = _retracting_seg
					var retract_dir = _retracting_seg.position.direction_to(_root_seg.position)
					var retract_dir_2 = _root_seg.position.direction_to(_retracting_seg.get_child_seg().get_child_seg().get_child_seg().get_child_seg().get_child_seg().get_child_seg().position)
					const FORCE_STRENGTH = 135.0
					var force = retract_dir * FORCE_STRENGTH
					var force_2 = retract_dir_2 * FORCE_STRENGTH
					_retracting_seg.apply_central_force(force)
					_retracting_seg.get_child_seg().apply_central_force(force / 2)
					_retracting_seg.get_child_seg().get_child_seg().apply_central_force(force / 2)
					_root_seg.apply_central_force(force.rotated(PI) * 0.3 + force_2 * 0.35)
					const MIN_DIST = 4
					if _retracting_seg.position.distance_to(_root_seg.position) < MIN_DIST:
						_retracting_seg.queue_free()
						_root_seg.get_node("PinJoint2D").node_b = _retracting_seg.get_child_seg().get_path()
						_root_seg.get_node("PinJoint2D").softness = 0.0
						_segs -= 1
						_retracting_seg = null
						_root_seg.detached_child = null
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
			child.position += gap 
			child._set_pos = child.position
			child.rotation = global_rotation
			child._set_rot = global_rotation
			_root_seg.set_child(child)

func _add_seg():
	var child : Vine = _root_seg.get_child_seg()
	
	var new_child : Vine = vine_creator.create(child)
	$Vines.add_child(new_child)
	new_child.make_self_exception()
	new_child.add_collision_exception_with(child)
	new_child.position = child.position
	new_child.rotation = child.rotation
	
	child.position = child.position + Vector2(0, _len_per_seg / 1.5).rotated(global_rotation)
	child._set_pos = child.position
	child.rotation = global_rotation
	child._set_rot = global_rotation

	_root_seg.get_node("PinJoint2D").node_b = new_child.get_path()
	_segs += 1
	

func _on_bg_music_finished():
	$Sound/BGMusic.play()

func _on_sunrays_hit():
	match tower.weather:
		Tower.Weather.SUNNY:
			if _state == State.EXTENDING:
				_has_sun_buff = true
		Tower.Weather.STORMY:
			_has_lightning_buff = true
			#print("lightning hit")

func _on_stuck_timer_timeout():
	_can_nudge = true
	pass



func _on_sprite_2d_animation_looped():
	if _sprite.animation == "spiked":
		_sprite.frame = 3
		_sprite.pause()
	elif _sprite.animation == "retract":
		_sprite.animation = "normal"

func set_volume():
	var scene_manager = get_tree().get_first_node_in_group("scenemanager")
	$Sound/BGMusic.volume_db = scene_manager.sound_volume + scene_manager.sound_volume_offset2
