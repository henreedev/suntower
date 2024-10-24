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
#@export var max_extended_len := 1250.0
#const BASE_MAX_EXTENDED_LEN := 1250.0
#const EXTEND_SPEED = 90.0
const EXTEND_SPEED = 110.0
var extend_speed_mod = 1.0
var extra_len = 0.0
var extra_len_display = 0.0
var wind_extra_len_display = BASE_MAX_EXTENDED_LEN
var vine_len_display = BASE_MAX_EXTENDED_LEN
var time = 0.0

var spiked_hitbox_tween : Tween

var music_tween : Tween

var initial_flower_pos := Vector2(0, -44)
var initial_pot_pos := Vector2(0, 6)

# Sun buff
var _has_sun_buff := false
var _sun_buff_applied := false
var sun_buff_tween : Tween

# Lightning buff
var _has_lightning_buff := false
var lightning_buff_tween : Tween
const MAX_LIGHTNING_BUFF = BASE_MAX_EXTENDED_LEN / 2.0
var lightning_buff_amount = 0.0
var lightning_buff_display = 0.0
const LIGHTNING_SPEED = 2.5
var lightning_speed_mod = 1.0
const base := Color(0.5, 1.0, 1.0, 1.0)

# Flower state
var _state : State = State.INACTIVE
var _animating = false
var base_segments := 15
var _segs := 15
var stuck = false # inactive and stuck
var dead = false # extending and stuck
var _prev_segs := _segs
var _set_transform 
var fixing_gap = false
var _target_angle : float
var _len_per_seg : float
var _extending_dist_travelled := 0.0
var _extended_len := 0.0
var _root_seg : Vine
var _first_seg : Vine
var _retracting_seg : Vine
var can_extend := true
var _can_nudge = false

var _len_per_seg_adj

const WIND_BUFF_DURATION = 0.1
var wind_buff_time_left = 0.0
var has_wind_buff := false
var wind_direction : Vector2
var active_wind_beam_strength_mod := 0.0
var wind_tween : Tween
var wind_dot : float # Used in speed calculation in beam, and for bar modulate

# Onready references to other nodes
@onready var _last_pos : Vector2 = position
@onready var vine_line : Line2D = $Vines/Line2D
@onready var vine_creator : Vine = vine_seg.instantiate()
@onready var stuck_timer : Timer = $StuckTimer
@onready var dead_timer : Timer = $DeadTimer
@onready var main : Main = get_tree().get_first_node_in_group("main")
@onready var _player : Player2 = get_tree().get_first_node_in_group("player2")
@onready var _bar : TextureProgressBar = get_tree().get_first_node_in_group("hud")
@onready var _sprite : AnimatedSprite2D = $Smoothing2D/Sprite2D
@onready var tower : Tower = get_tree().get_first_node_in_group("tower")
@onready var storm_light : PointLight2D = $StormLight
@onready var lightning_particles : GPUParticles2D = $Lightning
@onready var sun_particles : GPUParticles2D = $Sparkles
@onready var scene_manager = get_tree().get_first_node_in_group("scenemanager")
@onready var camera_2d = $Camera2D
@onready var spiked_hitbox: CollisionPolygon2D = $SpikedHitbox
@onready var wind_particles: GPUParticles2D = %WindParticles
@onready var wind_gust_particles: GPUParticles2D = %WindGustParticles
@onready var wind_particles_mat: ParticleProcessMaterial = wind_particles.process_material
@onready var wind_gust_particles_mat: ParticleProcessMaterial = wind_gust_particles.process_material
@onready var beam_particles: GPUParticles2D = %BeamParticles
@onready var beam_particles_mat: ParticleProcessMaterial = beam_particles.process_material

@export var skip_game := false

# Called when the node enters the scene tree for the first time.
func _ready():
	# NOTE uncomment this to view entire level 
	if skip_game:
		create_tween().set_loops().tween_property(self, "position", Vector2(0, -4000), 5.0).from(Vector2.ZERO).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_spawn_vine()
	add_collision_exception_with(_player)
	camera_2d.limit_top = tower.cam_max_marker.global_position.y
	if play_animation_on_start:
		_animating = true
	begin_inactive()
	if play_animation_on_start:
		play_spawn_animation()
	else:
		no_cutscene_setup()

func no_cutscene_setup():
	create_tween().tween_property($Camera2D,"zoom", Vector2(3.0, 3.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($Camera2D, "offset", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	_set_electricity(0)
	create_tween().tween_property(get_tree().get_first_node_in_group("ui"), "offset", Vector2(0, 0), 1.0).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)

func _process(delta):
	_draw_line()
	_root_seg.make_self_exception()
	if not _animating:
		act_on_state()
		_update_lightning_buff(delta)
		_update_wind_buff(delta)
		time += delta

func play_spawn_animation():
	# Make vines and line invisible, tween fade them in
	get_tree().set_group("vine", "modulate", Color(1.0, 1.0, 1.0, 0.0))
	get_tree().set_group("vine", "linear_damp", 100.0)
	$Vines/Line2D.modulate = Color(1.0,1.0,1.0,0.0)
	_sprite.modulate = Color(1.0,1.0,1.0,0.0)
	$Camera2D.offset = Vector2(0, 6)
	$Camera2D.zoom = Vector2(15, 15)
	create_tween().tween_property($Camera2D,"zoom", Vector2(5.95, 5.95), 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($Camera2D,"offset", Vector2(0, 4), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	#await Timing.create_timer(self, 2.0)
	
	var offset_tween = create_tween()
	offset_tween.tween_property($Camera2D, "offset", Vector2(-80, 4), 1.5).from(Vector2(0, 4)).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	offset_tween.tween_property($Camera2D, "offset", Vector2(80, 4), 2.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	offset_tween.tween_property($Camera2D, "offset", Vector2(0, 4), 2.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	# 7 seconds of camera panning 
	await Timing.create_timer(self, 6.7)
	var delay = 1.95
	var i = -1
	for vine in get_tree().get_nodes_in_group("vine"):
		i = i + 1
		await Timing.create_timer(self, delay * 1.0 / (i+3))
		var tween = create_tween().set_parallel(true)
		tween.tween_property(vine, "modulate", Color(1.0,1.0,1.0,1.0), 0.5)
		var sprite_scale = Vector2(1.0, 1.4)
		tween.tween_property(vine, "sprite_scale", sprite_scale, 0.5).from(Vector2(1.0, 0.0)).set_ease(Tween.EASE_IN_OUT)
	for vine in get_tree().get_nodes_in_group("vine"):
		create_tween().tween_property(vine, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	create_tween().tween_property($Vines/Line2D, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	create_tween().tween_property(_sprite, "scale", Vector2(1.0, 1.0), 0.4).from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_sprite, "offset", Vector2(0.0, 0.0), 0.4).from(Vector2(0, 5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_sprite, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	get_tree().set_group("vine", "sprite_scale", Vector2(1.0, 0.5))
	# Finish animation
	create_tween().tween_property($Camera2D,"zoom", Vector2(3.0, 3.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property($Camera2D, "offset", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	await Timing.create_timer(self, 0.5)
	create_tween().tween_property(get_tree().get_first_node_in_group("ui"), "offset", Vector2(0, 0), 1.0).set_trans(Tween.TRANS_CUBIC)
	_animating = false
	get_tree().set_group("vine", "linear_damp", 1.0)

func _connect_sunrays():
	for sunrays in get_tree().get_nodes_in_group("sunrays"):
		sunrays.connect("sun_hit", _on_sunrays_hit)

func _draw_line():
	vine_line.clear_points()
	var vine_seg : Vine = _root_seg
	vine_line.add_point($RootVinePin.global_position)
	while(vine_seg):
		vine_line.add_point(vine_seg.get_avg_pos())
		vine_seg = vine_seg.get_child_seg() if not vine_seg.get_child_seg() is Player2 else null

var waiting_to_check = false
func _teleport_if_stuck():
	if _state == State.INACTIVE:
		stuck = not can_extend and _player.linear_velocity.length() < 100.0
		if stuck: 
			stuck_timer.start()
		else:
			if not waiting_to_check:
				waiting_to_check = true
				await Timing.create_timer(self, 1.0)
				waiting_to_check = false
			if not stuck:
				stuck_timer.stop()
	elif _state == State.RETRACTING:
		dead = _segs == _prev_segs and not Input.is_anything_pressed()
		if dead:
			if dead_timer.is_stopped():
				dead_timer.start()
		else:
			dead_timer.stop()
		_prev_segs = _segs

func _spawn_vine():
	var first_vine_pos = _player.position + _player.vine_root_offset
	var final_vine_pos = position + vine_root_offset 
	var diff = final_vine_pos - first_vine_pos
	_len_per_seg = diff.length() / base_segments
	_len_per_seg_adj = _len_per_seg
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
		_teleport_if_stuck()
	elif _state == State.INACTIVE:
		_teleport_if_stuck()

func begin_extending():
	if _state == State.INACTIVE and can_extend and not _animating:
		_state = State.EXTENDING
		_sprite.animation = "spiked"
		_sprite.play()
		if tower.weather == Tower.Weather.SUNNY:
			sun_particles.emitting = true
			sun_particles.amount = 5
		lock_rotation = false
		collision_mask = 13
		enable_spiked_hitbox()
		get_tree().call_group("vine", "set_grav", 0.1)
		stuck_timer.stop()
		dead_timer.stop()
		_player.gravity_scale = 1.0
		_player.linear_damp = 0.0
		linear_damp = 0.0
		_player.mass = 0.25
		extend_speed_mod = 1.0
		mass = 0.1
		create_tween().tween_property(self, "extend_speed_mod", 1.0, 0.3)

func enable_spiked_hitbox():
	if spiked_hitbox_tween:
		spiked_hitbox_tween.kill()
	spiked_hitbox_tween = create_tween()
	
	spiked_hitbox.disabled = false
	spiked_hitbox.scale = Vector2(0.4, 0.4)
	spiked_hitbox_tween.tween_property(spiked_hitbox, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_CUBIC)

func disable_spiked_hitbox():
	if spiked_hitbox_tween:
		spiked_hitbox_tween.kill()
	spiked_hitbox_tween = create_tween()
	spiked_hitbox_tween.tween_property(spiked_hitbox, "scale", Vector2.ONE * 0.4, 0.5).set_trans(Tween.TRANS_CUBIC)
	spiked_hitbox_tween.tween_property(spiked_hitbox, "disabled", true, 0)

func begin_inactive():
	_sprite.animation = "retract"
	_sprite.frame = 0
	_sprite.play()
	fixing_gap = true
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
	wind_extra_len_display = BASE_MAX_EXTENDED_LEN
	vine_len_display = BASE_MAX_EXTENDED_LEN
	physics_material_override.friction = 0.0
	disable_spiked_hitbox()
	sun_particles.emitting = false
	gravity_scale = GRAVITY
	lock_rotation = false
	get_tree().call_group("vine", "set_grav", -0.03)
	stuck_timer.stop()
	dead_timer.stop()
	_player.gravity_scale = 1.0
	_player.linear_damp = 0.0
	_player.mass = 1.0
	linear_damp = 0.0
	mass = 0.01

func begin_retracting():
	_state = State.RETRACTING
	get_tree().call_group("vine", "set_grav", 0.3)
	create_tween().tween_property($RootVinePin, "position", Vector2(0, 0), 0.5)
	physics_material_override.friction = 1.0
	stuck_timer.stop()
	_player.gravity_scale = 0.4
	_player.mass = 0.25
	linear_damp = 10.0
	linear_velocity = Vector2(0, 0)
	gravity_scale = 0.3
	_extending_dist_travelled = 0
	_extended_len = 0

func enable_wind_particles():
	wind_particles.emitting = true
	wind_gust_particles.emitting = true
	beam_particles.visible = true

func disable_wind_particles():
	wind_particles.emitting = false
	wind_gust_particles.emitting = false
	beam_particles.visible = false

func show_active_wind_particles():
	_spawn_wind_particle(randi_range(5, 20), wind_direction)

func _spawn_wind_particle(amount : int, dir : Vector2):
	var SPEED = 100.0
	for i in range(amount):
		var origin = global_position + Vector2(randf_range(-5, 5), randf_range(-20, 20)).rotated(dir.angle() + PI / 2)
		var rand_vel := (dir * SPEED * randf_range(0.8, 1.2)).rotated(0)
		beam_particles.emit_particle(Transform2D(0, Vector2.ONE, 0, origin), 
			rand_vel, Color.WHITE, Color.WHITE, 5)
	


func update_wind_particles(new_dir : Vector2i, new_strength : float, color_mod := Color.WHITE):
	const MOD = 2.0
	const GRAVITY_MOD = MOD / 2.0 # reduce the accel, just show wind's "velocity"
	var dir = Vector3(new_dir.x, 0, 0)
	wind_particles.modulate = color_mod
	wind_particles_mat.gravity = dir * new_strength * MOD
	wind_particles_mat.direction = dir
	wind_particles_mat.initial_velocity_min = new_strength
	wind_particles_mat.initial_velocity_min = new_strength
	wind_particles_mat.linear_accel_min = new_strength * MOD
	wind_particles_mat.linear_accel_max = new_strength * MOD
	
	beam_particles.modulate = color_mod
	beam_particles_mat.gravity = dir * new_strength * MOD
	beam_particles_mat.direction = dir
	beam_particles_mat.initial_velocity_min = new_strength
	beam_particles_mat.initial_velocity_min = new_strength
	beam_particles_mat.linear_accel_min = new_strength * MOD
	beam_particles_mat.linear_accel_max = new_strength * MOD
	
	wind_gust_particles_mat.gravity = dir * new_strength * MOD * 0.8
	wind_gust_particles_mat.direction = dir
	wind_gust_particles_mat.initial_velocity_min = new_strength
	wind_gust_particles_mat.initial_velocity_min = new_strength
	wind_gust_particles_mat.linear_accel_min = new_strength * MOD * 0.5
	wind_gust_particles_mat.linear_accel_max = new_strength * MOD 

func _integrate_forces(state):
	if not _animating:
		var pos = state.transform.get_origin()
		var rot = state.transform.get_rotation()
		if _set_transform:
			state.transform = _set_transform
			_set_transform = null
		if _state == State.EXTENDING:
			_target_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
			state.transform = Transform2D(lerp_angle(state.transform.get_rotation(), _target_angle, state.step * ROTATE_SPEED * lightning_speed_mod), state.transform.get_origin()) 
			state.angular_velocity = 0
			var lin_vel = Vector2(0, -EXTEND_SPEED * extend_speed_mod * lightning_speed_mod).rotated(rotation)
			if has_wind_buff: 
				const WIND_ACTIVE_BEAM_STRENGTH = 45.0
				lin_vel += wind_direction * WIND_ACTIVE_BEAM_STRENGTH * active_wind_beam_strength_mod
			state.linear_velocity = lin_vel
		elif _state == State.RETRACTING:
			var dir = Vector2(0.0, 0.0)
			if Input.is_action_pressed("move_left") and not _animating:
				dir += Vector2(-1.0, 0.0)
			if Input.is_action_pressed("move_right") and not _animating:
				dir += Vector2(1.0, 0.0)
			var STR = _player.linear_velocity.length() / 250.0
			if dir.x > 0:
				dir += Vector2.from_angle(_player.rotation) * STR
			elif dir.x < 0:
				dir += -Vector2.from_angle(_player.rotation) * STR
			dir = dir.normalized()
			const MOVE_STRENGTH = 105.0
			_player.apply_central_force(dir * MOVE_STRENGTH)
		elif _state == State.INACTIVE:
			var mouse_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
			const STR = 6.0
			state.transform = Transform2D(lerp_angle(rotation, mouse_angle, STR * state.step), state.transform.get_origin())
			if can_extend:
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
	sun_particles.emitting = true
	sun_particles.amount = 125

func get_height():
	return -int(global_position.y)

func _physics_process(delta):
	if not _animating:
		can_extend = _player.touching and _player.linear_velocity.length_squared() < 2.0 or _state == State.EXTENDING
		var pos = position
		match _state:
			State.EXTENDING:
				if _has_sun_buff and not _sun_buff_applied and tower.weather == Tower.Weather.SUNNY:
					extra_len = BASE_MAX_EXTENDED_LEN
					extra_len_display = BASE_MAX_EXTENDED_LEN
					_sun_buff_applied = true
					_display_sun_buff()
				var dist_travelled = _last_pos.distance_to(pos)
				_extending_dist_travelled += dist_travelled
				if has_wind_buff:
					if extra_len < BASE_MAX_EXTENDED_LEN:
						wind_dot = _last_pos.direction_to(pos).dot(wind_direction)
						wind_dot = maxf(wind_dot, 0.0)
						extra_len += dist_travelled * wind_dot
						extra_len_display += dist_travelled * wind_dot
					elif extra_len > BASE_MAX_EXTENDED_LEN:
						extra_len = BASE_MAX_EXTENDED_LEN
					wind_extra_len_display = BASE_MAX_EXTENDED_LEN - extra_len
				var mod = (1.0 / lightning_speed_mod)
				_len_per_seg_adj = _len_per_seg * mod
				if _extending_dist_travelled > _len_per_seg_adj:
					_add_seg()
					_extended_len += _len_per_seg_adj
					_extending_dist_travelled -= _len_per_seg_adj
					if extra_len and extra_len_display:
						extra_len_display -= _len_per_seg_adj
						if extra_len_display < 0.0: 
							# subtract this overflow from vine len display
							vine_len_display += extra_len_display
							extra_len_display = 0.0
					else: vine_len_display -= _len_per_seg_adj
					if lightning_buff_amount:
						lightning_buff_amount -= _len_per_seg_adj
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
	if _state == State.EXTENDING or fixing_gap:
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
		await Timing.create_timer(self, 0.1)
		fixing_gap = false

func _add_seg():
	var child : Vine = _root_seg.get_child_seg()
	var new_child : Vine = vine_creator.create(child)
	$Vines.add_child(new_child)
	new_child.make_self_exception()
	new_child.add_collision_exception_with(child)
	
	var adj = Vector2(0, _len_per_seg_adj).rotated(global_rotation)
	
	new_child.position = _root_seg.position + adj
	new_child._set_pos = new_child.position
	new_child.rotation = global_rotation
	new_child._set_rot = global_rotation
	
	child.position = _root_seg.position + adj * 2
	child._set_pos = child.position
	child.rotation = global_rotation
	child._set_rot = global_rotation
	
	#new_child.linear_velocity = linear_velocity
	#child.linear_velocity = linear_velocity

	_root_seg.get_node("PinJoint2D").node_b = new_child.get_path()
	_segs += 1

func _get_lightning_buff():
	if not _has_lightning_buff:
		_has_lightning_buff = true
		lightning_particles.emitting = true
		lightning_particles.amount = 20
		sun_particles.emitting = false
		lightning_buff_amount = MAX_LIGHTNING_BUFF
		lightning_buff_display = MAX_LIGHTNING_BUFF
		lightning_speed_mod = LIGHTNING_SPEED
		if lightning_buff_tween:
			lightning_buff_tween.kill()
		lightning_buff_tween = create_tween().set_parallel()
		lightning_buff_tween.tween_property(storm_light, "texture_scale", 0.85, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_property(storm_light, "color", base, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_property(storm_light, "energy", 2.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_method(_set_electricity, 1.5, 2.5, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		lightning_buff_amount = MAX_LIGHTNING_BUFF
		lightning_buff_display = MAX_LIGHTNING_BUFF
		lightning_speed_mod = LIGHTNING_SPEED

func _update_lightning_buff(delta):
	if _has_lightning_buff:
		if lightning_buff_amount <= 0:
			_remove_lightning_buff()
		else:
			var buff_ratio = lightning_buff_amount / MAX_LIGHTNING_BUFF
			var goal_scale = 0.15 + buff_ratio * 0.3 if not _state == State.EXTENDING else 0.5 + 0.5 * buff_ratio
			var goal_color = base if not _state == State.EXTENDING else base
			var goal_energy = 0.5 * buff_ratio + 0.25 if not _state == State.EXTENDING else 0.75 + 0.25 * buff_ratio
			const STR = 1.0
			storm_light.texture_scale = lerp(storm_light.texture_scale, goal_scale, delta * STR) 
			storm_light.color = lerp(storm_light.color, goal_color, delta * STR)
			storm_light.energy = lerp(storm_light.energy, goal_energy, delta * STR)
			lightning_speed_mod = lerp(1.5, LIGHTNING_SPEED, buff_ratio)
			_set_electricity(lerp(1.5, 2.5, buff_ratio))


func _remove_lightning_buff():
	if _has_lightning_buff:
		_has_lightning_buff = false
		lightning_buff_amount = 0.0
		lightning_buff_display = 0.0
		lightning_speed_mod = 1.0
		if lightning_buff_tween:
			lightning_buff_tween.kill()
		lightning_buff_tween = create_tween().set_parallel()
		lightning_buff_tween.tween_property(storm_light, "texture_scale", 0.15, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_property(storm_light, "color", Color(1, 1, 1, 1), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_property(storm_light, "energy", 0.15, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_method(_set_electricity, 1.5, 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await Timing.create_timer(self, 0.5)
		lightning_particles.emitting = false


func _set_electricity(val):
	_sprite.material.set_shader_parameter("electricity", max(val, 0.0))
	get_tree().call_group("vine", "_set_electricity", val)
	vine_line.material.set_shader_parameter("electricity", max(val, 0.0))

func _get_wind_buff():
	if not has_wind_buff:
		_update_wind_dir()
		show_active_wind_particles()
		if wind_tween: wind_tween.kill()
		wind_tween = create_tween()
		wind_tween.tween_property(self, "active_wind_beam_strength_mod", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
		wind_dot = 0.0
	has_wind_buff = true
	wind_buff_time_left = WIND_BUFF_DURATION

func _update_wind_dir():
	const HALF_PI = PI / 2
	wind_direction = Vector2.from_angle(tower._lights.rotation + HALF_PI)

func _update_wind_buff(delta):
	if has_wind_buff:
		_update_wind_dir()
		main.set_vine_windiness(wind_dot)
		if wind_buff_time_left > 0:
			wind_buff_time_left -= delta
		else:
			_remove_wind_buff()
	

func _remove_wind_buff():
	if has_wind_buff:
		has_wind_buff = false
		if wind_tween: wind_tween.kill()
		active_wind_beam_strength_mod = 0
		main.set_vine_windiness(0.0)


func _on_sunrays_hit():
	match tower.weather:
		Tower.Weather.SUNNY:
			if _state == State.EXTENDING:
				_has_sun_buff = true
		Tower.Weather.STORMY:
			_get_lightning_buff()
		Tower.Weather.WINDY:
			if _state == State.EXTENDING:
				_get_wind_buff()

func _on_stuck_timer_timeout():
	unstuck()

func _on_dead_timer_timeout():
	unstuck()

func unstuck():
	position = _player.global_position
	get_tree().set_group("vine", "global_position", _player.global_position - Vector2(0, 10))

func _on_sprite_2d_animation_looped():
	if _sprite.animation == "spiked":
		_sprite.frame = 3
		_sprite.pause()
	elif _sprite.animation == "retract":
		_sprite.animation = "normal"
