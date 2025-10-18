extends RigidBody2D
class_name Head

enum State {INACTIVE, EXTENDING, RETRACTING}

# Constants
const ROTATE_SPEED = PI * 1.5
const HEAD_GRAVITY = -0.2 # Head floats upwards
const VINE_ROOT_OFFSET := Vector2(0, 5)
const EXTEND_SPEED = 110.0
const BASE_MAX_EXTENDED_LEN := 125.0
const VINE_SCENE : PackedScene = preload("res://scenes/character/Vine.tscn")

# Gameplay control variables
var play_animation_on_start : bool # Set by SceneManager

# Display values of resources, for HUD to use
var vine_len_display = BASE_MAX_EXTENDED_LEN
var wind_extra_len_display = BASE_MAX_EXTENDED_LEN
var lightning_buff_display = 0.0

## Flower state
var _state : State = State.INACTIVE
var _animating = false
var base_segments := 15
var _segs := 15
var stuck = false # inactive and stuck
var dead = false # extending and stuck
var _prev_segs := _segs
var _set_transform
var fixing_gap = false
var can_extend := true
var ignore_extension_limit := false
var _can_nudge = false
var should_teleport := false
var rotation_while_retracting_enabled := false

# Camera variables
var target_y_offset := 0.0

# Extension/retraction variables
@export var max_extended_len := 125.0
var _len_per_seg_base : float ## Calculated on initialization
var _len_per_seg : float ## Adjusted by a scalar
## Amount past base length we've travelled, but decrements by _len_per_seg upon reaching that value. 
var _extending_dist_travelled := 0.0 
## Total amount we've extended past base length
var _extended_len := 0.0 
var _root_seg : Vine
var _first_seg : Vine
var _retracting_seg : Vine
var extra_len = 0.0 ## The amount of extra length added onto the current maximum length
var extra_len_display = 0.0 ## The current amount of the extra length remaining
const MAX_FORCE_MOD := 4.0 ## Max slingshot force multiplier
var force_mod := 1.0 ## Increased when pressing slingshot
var slingshotting := false ## True after pressing slingshot input, until inactive
@onready var _last_pos : Vector2 = position

# Sun buff
var _has_sun_buff := false
var _sun_buff_applied := false

# Lightning buff
var _has_lightning_buff := false
const MAX_LIGHTNING_BUFF = BASE_MAX_EXTENDED_LEN
var lightning_buff_amount = 0.0
const LIGHTNING_SPEED = 2.0
var lightning_speed_mod = 1.0
const base := Color(0.5, 1.0, 1.0, 1.0)

# Wind buff
const WIND_BUFF_DURATION = 0.1
var wind_buff_time_left = 0.0
var has_wind_buff := false
var wind_direction : Vector2
var active_wind_beam_strength_mod := 0.0
var wind_dot : float # Used in speed calculation in beam, and for bar modulate
## How much total extra length has been added by the wind beam.
var wind_extra_len := 0.0

# Tweens
var spiked_hitbox_tween : Tween
var sun_buff_tween : Tween
var lightning_buff_tween : Tween
var wind_tween : Tween
var wind_particles_tween : Tween
var slingshot_tween : Tween


# Onready references to other nodes
@onready var vine_creator : Vine = VINE_SCENE.instantiate()
@onready var stuck_timer : Timer = $StuckTimer
@onready var dead_timer : Timer = $DeadTimer
@onready var game : Game = get_tree().get_first_node_in_group("game")
@onready var _pot : Pot = get_tree().get_first_node_in_group("pot")
@onready var _bar : TextureProgressBar = get_tree().get_first_node_in_group("hud")
@onready var _sprite : AnimatedSprite2D = %Sprite2D
@onready var dash_overlay: AnimatedSprite2D = $Sprite2D/DashOverlay
@onready var tower : Tower = get_tree().get_first_node_in_group("tower")
@onready var scene_manager : SceneManager = get_tree().get_first_node_in_group("scenemanager")
@onready var vine_line : Line2D = $Vines/Line2D
@onready var camera_2d = $Camera2D
@onready var storm_light : PointLight2D = $StormLight
@onready var spiked_hitbox: CollisionPolygon2D = $SpikedHitbox
@onready var occluders : Node2D = $Occluders/Node2D

# Particle system variables
@onready var sun_particles : GPUParticles2D = %Sparkles
@onready var lightning_particles : GPUParticles2D = %Lightning
@onready var wind_particles: GPUParticles2D = %WindParticles
@onready var wind_gust_particles: GPUParticles2D = %WindGustParticles
@onready var wind_particles_mat: ParticleProcessMaterial = wind_particles.process_material
@onready var wind_gust_particles_mat: ParticleProcessMaterial = wind_gust_particles.process_material
@onready var beam_particles: GPUParticles2D = %BeamParticles
@onready var beam_particles_mat: ParticleProcessMaterial = beam_particles.process_material
@onready var dash_charge_sparkles: GPUParticles2D = %DashChargeSparkles
@onready var dash_charge_sparkles_mat: ParticleProcessMaterial = dash_charge_sparkles.process_material


# Dev tools
@export var dev_mode := false # Enable to teleport with right click
@export var skip_game := false # Tweens head position to the top of the map on start

# Called when the node enters the scene tree for the first time.
# Spawns vine, plays cutscene, and sets important values 
func _ready():
	if skip_game:
		create_tween().set_loops().tween_property(self, "position", Vector2(0, -7000), 10.0).from(Vector2.ZERO).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	_spawn_vine()
	
	_wiggle_dash_overlay()
	
	camera_2d.limit_top = tower.cam_max_marker.global_position.y
	add_collision_exception_with(_pot)
	play_animation_on_start = not Values.skip_cutscene
	#play_animation_on_start = false # FIXME
	if play_animation_on_start:
		_animating = true 
	begin_inactive()
	
	if play_animation_on_start:
		play_spawn_animation()
	else:
		no_cutscene_setup()

# Play a cutscene where the camera pans around, and then the flower spawns in.
func play_spawn_animation():
	# Show drip and splash, syncing them 
	Tower.instance.water_drip.emitting = true 
	create_tween().tween_property(Tower.instance.water_splash, "emitting", true, 0.0).set_delay(1.32) 
	# Make vines and line invisible, tween fade them in
	get_tree().set_group("vine", "modulate", Color(1.0, 1.0, 1.0, 0.0))
	get_tree().set_group("vine", "linear_damp", 100.0)
	$Vines/Line2D.modulate = Color(1.0,1.0,1.0,0.0)
	_sprite.self_modulate = Color(1.0,1.0,1.0,0.0)
	camera_2d.offset = Vector2(0, 4)
	camera_2d.zoom = Vector2(15, 15)
	create_tween().tween_property(camera_2d,"zoom", Vector2(5.95, 5.95), 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	#create_tween().tween_property(camera_2d,"offset", Vector2(0, 4), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Tween camera to look left, then right, then center
	var offset_tween = create_tween()
	offset_tween.tween_property(camera_2d, "offset", Vector2(-80, 4), 1.5).from(Vector2(0, 4)).set_trans(Tween.TRANS_CUBIC).set_delay(1.0)
	offset_tween.tween_property(camera_2d, "offset", Vector2(80, 4), 2.3).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	offset_tween.tween_property(camera_2d, "offset", Vector2(0, 4), 2.4).set_trans(Tween.TRANS_CUBIC).set_delay(0.2)
	
	# Wait for camera panning to finish 
	await Timing.create_timer(self, 6.7)
	
	# Spawn in vines and flower
	#var delay = 1.95
	var delay = 1.75
	var i = -1
	for vine in get_tree().get_nodes_in_group("vine"):
		await Timing.create_timer(self, delay * 1.0 / (i+3))
		var tween = create_tween().set_parallel(true)
		tween.tween_property(vine, "modulate", Color(1.0,1.0,1.0,1.0), 0.5)
		var sprite_scale = Vector2(1.0, 1.4)
		tween.tween_property(vine, "sprite_scale", sprite_scale, 0.5).from(Vector2(1.0, 0.0)).set_ease(Tween.EASE_IN_OUT)
		i = i + 1
	
	# Flash everything bright after vine spawning complete, spawn flower
	for vine in get_tree().get_nodes_in_group("vine"):
		var tween = create_tween()
		tween.tween_property(vine, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
		tween.tween_property(vine, "sprite_scale", Vine.BASE_SPRITE_SCALE, 0.5).from(Vector2(1.0, 0.0)).set_ease(Tween.EASE_IN_OUT)
	
	create_tween().tween_property($Vines/Line2D, "modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	create_tween().tween_property(_sprite, "scale", Vector2(1.0, 1.0), 0.4).from(Vector2(0.5, 0.5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_sprite, "offset", Vector2(0.0, 0.0), 0.4).from(Vector2(0, 5)).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_sprite, "self_modulate", Color(1.0,1.0,1.0,1.0), 0.75).from(Color(10, 10, 10, 0.0))
	#get_tree().set_group("vine", "sprite_scale", Vector2(1.0, 0.5))
	
	# Reset camera
	create_tween().tween_property(camera_2d,"zoom", Vector2(3.0, 3.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(camera_2d, "offset", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	await Timing.create_timer(self, 0.5)
	
	# Start gameplay
	Values.skip_cutscene = true # Don't play the cutscene again until the game closes or is won.
	_animating = false
	tower.water_drip.emitting = false
	tower.water_splash.emitting = false
	tower.tutorial_chunk.start_tutorial()
	get_tree().set_group("vine", "linear_damp", 1.0)
	game.switch_to_sun_bar()

# No cutscene should be played; do basic setup. If speedrunning, do a little animation.
func no_cutscene_setup():
	create_tween().tween_property(camera_2d,"zoom", Vector2(3.0, 3.0), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	create_tween().tween_property(camera_2d, "offset", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	
	# Avoid accessing Values before it's loaded from save 
	if not scene_manager.is_initialized: await scene_manager.initialized
	
	if Values.speedrun_mode:
		_animating = true
		var speedrun_intro_tween := create_tween()
		# Avoid accessing game before it's initialized
		if not game.is_initialized: await game.initialized
		
		game.switch_to_sun_bar()
		
		# Animate speedrun timer moving to top-right corner, and lock movement during this
		var initial_pos = game.speedrun_timers.position
		var initial_tracker_pos = game.time_trackers[0].position
		var initial_tracker_scale = game.time_trackers[0].scale
		game.time_trackers[0].position = Vector2.ZERO   # center screen
		game.time_trackers[0].scale = Vector2.ONE * 3   # center screen
		game.speedrun_timers.position = Vector2(576, 342) - game.time_trackers[0].size / 2  # center screen
		speedrun_intro_tween.tween_property(game.speedrun_timers, "position", initial_pos, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).set_delay(1.0)
		speedrun_intro_tween.parallel().tween_property(game.time_trackers[0], "position", initial_tracker_pos, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).set_delay(1.0)
		speedrun_intro_tween.parallel().tween_property(game.time_trackers[0], "scale", initial_tracker_scale, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).set_delay(1.0)
		speedrun_intro_tween.tween_property(self, "_animating", false, 0.0)
		speedrun_intro_tween.tween_callback(game.shake.bind(1.5))
	else:
		# Avoid accessing game before it's initialized
		if not game.is_initialized: await game.initialized
		
		game.switch_to_sun_bar()
		
		tower.tutorial_chunk.start_tutorial()

# Refreshes line and updates state and buffs.
func _process(delta):
	_draw_line()
	_root_seg.make_self_exception()
	if not _animating:
		act_on_state()
		_update_lightning_buff(delta)
		_update_wind_buff(delta)
		process_dash_logic(delta)
		_process_camera_offset(delta)

# Listens for dev-related inputs.
func _input(event):
	if event.is_action_pressed("clear_user_data"):
		Values.clear_user_data()
	if event.is_action_pressed("toggle_dev_mode"):
		dev_mode = not dev_mode
	if event.is_action_pressed("toggle_rotation_while_retracting"):
		rotation_while_retracting_enabled = not rotation_while_retracting_enabled
	if dev_mode and event.is_action_pressed("dev_teleport"):
		should_teleport = true
		Values.cheated = true

# Draws a line connecting the vine segments.
func _draw_line():
	vine_line.clear_points()
	var vine_seg : Vine = _root_seg
	vine_line.add_point($RootVinePin.global_position)
	while(vine_seg):
		# TODO add gradient lighting up with sunlight here
		vine_line.add_point(vine_seg.get_avg_pos()) 
		vine_seg = vine_seg.get_child_seg() if not vine_seg.get_child_seg() is Pot else null

## Triggers the sunlight vfx chain on the root segment. 
func trigger_vine_sunlight_vfx_chain():
	if _root_seg:
		_root_seg.trigger_sunlight_vfx_chain(100.0)


var waiting_to_check = false # Used to check stuck condition once per second
# Checks conditions to teleport the head to the pot when the head is stuck.
@export var should_check_if_stuck = true
func _teleport_if_stuck():
	if not should_check_if_stuck: return
	
	if _state == State.INACTIVE:
		stuck = not can_extend and _pot.linear_velocity.length() < 100.0
		if stuck:
			stuck_timer.start() # Help the player after a delay
		else:
			if not waiting_to_check:
				waiting_to_check = true
				await Timing.create_timer(self, 1.0) # Don't check for a second
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

# Spawns vine segments, equally spaced from the head to the pot. Links them together with pin joints.
func _spawn_vine():
	var first_vine_pos = _pot.position + _pot.VINE_ROOT_OFFSET
	var final_vine_pos = position + VINE_ROOT_OFFSET
	var diff = final_vine_pos - first_vine_pos
	
	_len_per_seg_base = diff.length() / base_segments
	_len_per_seg = _len_per_seg_base
	
	var curr_seg : Vine = null
	var last_seg : Vine = null
	 
	# Make vine segments from the pot to the flower, pinning them to each other.
	# Connect the last segment to the flower.
	for i in base_segments:
		if i == 0:
			curr_seg = vine_creator.create(_pot)
			_first_seg = curr_seg
			#_first_seg.lock_rotation = true # Causes pot to get stuck going over corners
		else:
			curr_seg = vine_creator.create(last_seg)
		var progress = diff * float(i) / base_segments
		var seg_pos = first_vine_pos + progress
		curr_seg.position = seg_pos
		$Vines.add_child(curr_seg)
		curr_seg.make_self_exception()
		if i == 0:
			curr_seg.set_child(_pot)
		if i == base_segments - 1:
			$RootVinePin.node_b = curr_seg.get_path()
			_root_seg = curr_seg
		last_seg = curr_seg

## Checks state guards and/or sets certain variables.
func act_on_state():
	if _state == State.EXTENDING:
		if Input.is_action_just_released("extend") and not _animating:
			begin_retracting()
	elif _state == State.RETRACTING:
		lock_rotation = true
		if _segs <= base_segments:
			begin_inactive()
		# Enable extension while retracting here:
		#elif Input.is_action_just_pressed("extend"):
			#begin_extending()
		elif can_dash and Input.is_action_pressed("dash"):
			dash()
		_teleport_if_stuck()
	elif _state == State.INACTIVE:
		if Input.is_action_just_pressed("extend") and not Input.is_action_pressed("dash"):
			begin_extending()
		_teleport_if_stuck()

## Sets physical variables related to extension.
## Overall, the head moves in the direction of rotation and rotates linearly towards the mouse,
##  and the vines and pot lose gravity.  
func begin_extending():
	if\
	 #_state == State.INACTIVE and \
	 can_extend and not _animating:
		_state = State.EXTENDING
		
		# Show spikes
		_sprite.animation = "spiked"
		_sprite.play()
		enable_spiked_hitbox()
		
		# Sparkles during extension
		if tower.weather == Tower.Weather.SUNNY:
			sun_particles.emitting = true
			sun_particles.amount = 5
		
		lock_rotation = false
		collision_mask = 1 + 4 + 8
		
		get_tree().call_group("vine", "set_grav", 0.1)
		
		_pot.gravity_scale = 1.0
		_pot.linear_damp = 250.0
		_pot.angular_damp = 10.0
		_pot.mass = 0.25
		
		linear_damp = 0.0
		mass = 0.1
		
		# Dash if charged
		if can_dash and dash_charge_amount > 0.0:
			dash()
		
		stuck_timer.stop()
		dead_timer.stop()

# Sets physical variables related to being inactive.
# Overall, the head floats upwards and aims at the mouse, while the pot and vine have normal mass and gravity.  
func begin_inactive():
	_state = State.INACTIVE
	
	# Show retraction
	_sprite.animation = "retract"
	_sprite.frame = 0
	_sprite.play()
	disable_spiked_hitbox()
	
	# Remove the gap in the neck
	fixing_gap = true
	
	_has_sun_buff = false
	_sun_buff_applied = false
	sun_particles.emitting = false
	if sun_buff_tween:
		sun_buff_tween.kill()
	sun_buff_tween = create_tween()
	sun_buff_tween.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.6)
	
	# Don't collide with Props
	#collision_mask = 13
	collision_mask = 1 + 8
	
	# Remove buff bonuses
	max_extended_len = BASE_MAX_EXTENDED_LEN
	_extended_len = 0.0
	extra_len = 0.0
	wind_extra_len = 0.0
	extra_len_display = 0.0
	wind_extra_len_display = BASE_MAX_EXTENDED_LEN
	vine_len_display = BASE_MAX_EXTENDED_LEN
	
	# Restore dash ability
	can_dash = true
	dash_charge_amount = 0.0
	
	
	physics_material_override.friction = 0.0
	lock_rotation = false

	mass = 0.01
	linear_damp = 0.0
	gravity_scale = HEAD_GRAVITY

	_pot.mass = 1.0
	if not slingshotting: # Let the pot move more quickly if slingshotting
		_pot.linear_damp = 1.01
	_pot.angular_damp = 3.0
	_pot.gravity_scale = 1.0
	
	# Reset slingshot variables
	slingshotting = false
	if slingshot_tween: slingshot_tween.kill()
	force_mod = 1.0
	
	get_tree().call_group("vine", "set_grav", -0.03)
	get_tree().set_group("vine", "linear_damp", 1.0)
	get_tree().set_group("vine", "angular_damp", 20.0)
	
	
	stuck_timer.stop()
	dead_timer.stop()

# Sets physical variables related to being inactive.
# Overall, the head moves towards the vines with drag, and the the pot has normal mass and no drag.
func begin_retracting():
	_state = State.RETRACTING
	
	if _segs > 60 and tower.weather == Tower.Weather.STORMY:
		get_tree().call_group("vine", "set_grav", 0.0) # Avoid issues with too many segments being heavy
	else:
		get_tree().call_group("vine", "set_grav", 0.3)
	
	create_tween().tween_property($RootVinePin, "position", Vector2(0, 0), 0.5)
	
	physics_material_override.friction = 2.5
	_pot.gravity_scale = 0.43
	_pot.mass = 0.28
	_pot.linear_damp = 1.0
	_pot.angular_damp = 2.0
	linear_damp = 10.0
	linear_velocity = Vector2(0, 0)
	gravity_scale = 0.3
	
	_extending_dist_travelled = 0
	#_extended_len = 0
	
	stuck_timer.stop()

# Enables the spikes on the flower's head.
func enable_spiked_hitbox():
	if spiked_hitbox_tween:
		spiked_hitbox_tween.kill()
	spiked_hitbox_tween = create_tween()
	
	spiked_hitbox.disabled = false
	spiked_hitbox.scale = Vector2(0.4, 0.4)
	spiked_hitbox_tween.tween_property(spiked_hitbox, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_CUBIC)

# Disables the spikes on the flower's head.
func disable_spiked_hitbox():
	if spiked_hitbox_tween:
		spiked_hitbox_tween.kill()
	spiked_hitbox_tween = create_tween()
	spiked_hitbox_tween.tween_property(spiked_hitbox, "scale", Vector2.ONE * 0.4, 0.5).set_trans(Tween.TRANS_CUBIC)
	spiked_hitbox_tween.tween_property(spiked_hitbox, "disabled", true, 0)

# Enables wind particles with a fade-in.
func enable_wind_particles():
	const DUR = 1.0
	wind_particles.emitting = true
	wind_particles.visible = true
	wind_gust_particles.emitting = true
	wind_gust_particles.visible = true
	beam_particles.visible = true
	if wind_particles_tween: wind_particles_tween.kill()
	wind_particles_tween = create_tween().set_parallel()
	wind_particles_tween.tween_property(wind_particles, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_CUBIC).from(0.0)
	wind_particles_tween.tween_property(wind_gust_particles, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_CUBIC).from(0.0)
	wind_particles_tween.tween_property(beam_particles, "modulate:a", 1.0, DUR).set_trans(Tween.TRANS_CUBIC).from(0.0)

# Disables wind particles with a fade-out.
func disable_wind_particles():
	const DUR = 1.0
	wind_particles.emitting = true
	wind_particles.visible = true
	wind_gust_particles.emitting = true
	wind_gust_particles.visible = true
	beam_particles.visible = true
	if wind_particles_tween: wind_particles_tween.kill()
	wind_particles_tween = create_tween().set_parallel()
	wind_particles_tween.tween_property(wind_particles, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_CUBIC)
	wind_particles_tween.tween_property(wind_gust_particles, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_CUBIC)
	wind_particles_tween.tween_property(beam_particles, "modulate:a", 0.0, DUR).set_trans(Tween.TRANS_CUBIC)
	
	wind_particles_tween.tween_property(wind_particles, "emitting", false, 0.0).set_delay(DUR)
	wind_particles_tween.tween_property(wind_gust_particles, "emitting", false, 0.0).set_delay(DUR)
	wind_particles_tween.tween_property(wind_particles, "visible", false, 0.0).set_delay(DUR)
	wind_particles_tween.tween_property(wind_gust_particles, "visible", false, 0.0).set_delay(DUR)
	wind_particles_tween.tween_property(beam_particles, "visible", false, 0.0).set_delay(DUR)

# Spawns wind particles flying in the direction of the wind beam.
func show_active_wind_particles():
	_spawn_wind_particle(randi_range(5, 20), wind_direction)

# Spawns a wind particle somewhere along the wind beam near the flower head, moving in wind direction.
func _spawn_wind_particle(amount : int, dir : Vector2):
	var SPEED = 100.0
	for i in range(amount):
		var origin = global_position + Vector2(randf_range(-5, 5), randf_range(-20, 20)).rotated(dir.angle() + PI / 2)
		var rand_vel := (dir * SPEED * randf_range(0.8, 1.2)).rotated(0)
		beam_particles.emit_particle(Transform2D(0, Vector2.ONE, 0, origin),
			rand_vel, Color.WHITE, Color.WHITE, 5)

# Updates wind particle system variables to show the wind direction and strength.
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

# Enables occluders. These block light far above and below the Head's position.
#  TileMaps don't occlude light if they're too far off screen, so this fixes that issue
func enable_occluders():
	occluders.visible = true

# Disables occluders.
func disable_occluders():
	occluders.visible = false

# Performs extension and retraction movements every physics update.
func _integrate_forces(state):
	if not _animating:
		var pos = state.transform.get_origin()
		var rot = state.transform.get_rotation()
		
		if _set_transform:
			state.transform = _set_transform
			_set_transform = null
		
		if _state == State.EXTENDING:
			# Slow movement and rotation speeds when little length is left
			var slow_multiplier = 1.0
			const SLOWDOWN_LENGTH = 50.0
			var remaining_length = (max_extended_len - _extended_len)
			if remaining_length < SLOWDOWN_LENGTH:
				slow_multiplier = lerpf(0.25, 1.0, remaining_length / SLOWDOWN_LENGTH) # As length remaining approaches 0, slow down more
			
			# Rotate steadily towards mouse
			var target_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
			var new_angle = lerp_angle(state.transform.get_rotation(), target_angle, state.step \
				* ROTATE_SPEED * lightning_speed_mod * 
				(dash_turn_strength if is_dashing else 1.0) 
				* slow_multiplier
			)
			state.transform = Transform2D(new_angle, state.transform.get_origin())
			#state.angular_velocity -= 5.0 * state.angular_velocity * state.step 
			state.angular_velocity = 0.0
			
			
			
			# Add to linear velocity if dashing
			var lin_vel = state.linear_velocity
			var base_y_vel = -EXTEND_SPEED * lightning_speed_mod
			if is_dashing:
				var dash_y_vel = -dash_force_strength
				base_y_vel = max(base_y_vel, dash_y_vel)
				lin_vel = Vector2(0, dash_y_vel).rotated(rotation)
			else:
				# Move in direction of rotation
				lin_vel = Vector2(0, base_y_vel).rotated(rotation)
				# Calculate slow multiplier for dash
				lin_vel *= slow_multiplier
			
			# Get pushed by wind beam
			if has_wind_buff:
				const WIND_ACTIVE_BEAM_STRENGTH = 45.0
				lin_vel += wind_direction * WIND_ACTIVE_BEAM_STRENGTH * active_wind_beam_strength_mod
			
			state.linear_velocity = lin_vel
			
		elif _state == State.RETRACTING:
			# Do slingshot
			if Input.is_action_just_pressed("slingshot") and not slingshotting:
				slingshotting = true
				if slingshot_tween: slingshot_tween.kill()
				slingshot_tween = create_tween()
				_pot.linear_damp = 0.0
				_pot.mass = 0.5
				slingshot_tween.tween_property(self, "force_mod", MAX_FORCE_MOD, 2.0)
				get_tree().set_group("vine", "linear_damp", 0.0)
				get_tree().set_group("vine", "angular_damp", 2.0)
			
			# Rotate steadily towards mouse
			if rotation_while_retracting_enabled:
				var target_angle = pos.angle_to_point(get_global_mouse_position()) + PI/2
				var new_angle = lerp_angle(state.transform.get_rotation(), target_angle, state.step \
					* ROTATE_SPEED * 0.5 * lightning_speed_mod)
				state.transform = Transform2D(new_angle, state.transform.get_origin())
				state.angular_velocity = 0
			
			# Move the pot by inputs
			_do_pot_movement()
		
		elif _state == State.INACTIVE:
			const TURN_STRENGTH = 6.0
			var mouse_angle = pos.angle_to_point(get_global_mouse_position()) + PI / 2
			var new_angle = lerp_angle(rotation, mouse_angle, TURN_STRENGTH * state.step)
			state.transform = Transform2D(new_angle, state.transform.get_origin())
			# Allow A/D movement if not touching
			if not _pot.touching:
				_do_pot_movement()
			if can_extend:
				const MOVE_STRENGTH = 20.0
				var force_toward_mouse = Vector2.UP.rotated(mouse_angle) * MOVE_STRENGTH
				apply_central_force(force_toward_mouse)
			# Shrink down towards pot when charging a dash to show the "windup"
			if dash_charge_amount > 0.0:
				# Apply a force towards pot
				const DASH_CHARGE_FORCE_STRENGTH = 23.0
				var force_toward_pot = global_position.direction_to(_pot.global_position) * DASH_CHARGE_FORCE_STRENGTH
				apply_central_force(force_toward_pot)
		
		# Fix the neck gap based on state
		_fix_gap(state)

## Performs pot left / right movement based on input.
func _do_pot_movement():
	if _animating: return
	# Swing the pot left or right
	var dir = Vector2(0.0, 0.0)
	if Input.is_action_pressed("move_left"):
		dir += Vector2(-1.0, 0.0)
	if Input.is_action_pressed("move_right"):
		dir += Vector2(1.0, 0.0)
	
	if dir != Vector2.ZERO:
		# Don't just move horizontally (x-axis), but also horizontally from the pot's perspective
		var STR = _pot.linear_velocity.length() / 250.0
		if dir.x > 0:
			dir += Vector2.from_angle(_pot.rotation) * STR
		elif dir.x < 0:
			dir += -Vector2.from_angle(_pot.rotation) * STR
		dir = dir.normalized()
		
		var MOVE_STRENGTH = 220.0 + (110.0 if _state == State.RETRACTING else 0.0)
		_pot.apply_central_force(dir * MOVE_STRENGTH * _pot.mass)

# Displays the sun buff, tinting the head and spawning more particles
func _display_sun_buff():
	if sun_buff_tween:
		sun_buff_tween.kill()
	sun_buff_tween = create_tween()
	var tween_2 = create_tween()
	sun_buff_tween.tween_property(_sprite, "modulate", Color(4, 4, 4), 0.5)
	tween_2.tween_property(_bar, "tint_progress", Color(2, 2, 2), 0.5)
	sun_buff_tween.tween_property(_sprite, "modulate", Color(2.0, 2.0, 2.0), 1.5)
	tween_2.tween_property(_bar, "tint_progress", Color(1., 1., 1.), 0.5)
	sun_particles.emitting = true
	sun_particles.amount = 125

# Returns the head's height relative to the bottom of the tower.
func get_height():
	return -int(global_position.y - tower.start_height)

# Tracks vine length and performs extension and retraction. 
func _physics_process(delta):
	if not _animating:
		# Player can extend if the pot is still
		can_extend = _pot.touching and _pot.linear_velocity.length_squared() < 2.0 or _state == State.EXTENDING or (_state == State.RETRACTING and _extended_len > 0)
		
		var pos = position
		
		match _state:
			State.EXTENDING:
				# Apply sun buff
				if _has_sun_buff and not _sun_buff_applied and tower.weather == Tower.Weather.SUNNY:
					extra_len = BASE_MAX_EXTENDED_LEN
					extra_len_display = BASE_MAX_EXTENDED_LEN
					_sun_buff_applied = true
					_display_sun_buff()
				
				var dist_travelled = _last_pos.distance_to(pos)
				_extending_dist_travelled += dist_travelled
				
				# Add length if extending along wind beam
				if has_wind_buff:
					if wind_extra_len < BASE_MAX_EXTENDED_LEN:
						wind_dot = _last_pos.direction_to(pos).dot(wind_direction)
						wind_dot = maxf(wind_dot, 0.0)
						wind_extra_len += dist_travelled * wind_dot
						extra_len_display += dist_travelled * wind_dot
					elif wind_extra_len > BASE_MAX_EXTENDED_LEN:
						wind_extra_len = BASE_MAX_EXTENDED_LEN
					wind_extra_len_display = BASE_MAX_EXTENDED_LEN - wind_extra_len
				
				# Spawn fewer segments when going fast
				var mod = (1.0 / lightning_speed_mod) # TODO incorporate dash bonus here too 
				_len_per_seg = _len_per_seg_base * mod
				
				# If we've traveled the length of a segment, add a segment to fill the gap
				if _extending_dist_travelled > _len_per_seg:
					_add_seg()
					_extended_len += _len_per_seg
					_extending_dist_travelled -= _len_per_seg
					
					# Use extra length to extend, if we have it
					if extra_len and extra_len_display:
						extra_len_display -= _len_per_seg
						if extra_len_display < 0.0:
							# Subtract overflow from vine len display
							vine_len_display += extra_len_display
							extra_len_display = 0.0
					else:
						# Use vine length to extend 
						vine_len_display -= _len_per_seg
					
					if lightning_buff_amount:
						lightning_buff_amount -= _len_per_seg
				
				# Clear retracting seg if it exists
				if _retracting_seg:
					# Root seg pins to the Vine after the retracting seg
					_root_seg.get_node("PinJoint2D").node_b = _retracting_seg.get_child_seg().get_path()
					_retracting_seg.queue_free()
					_retracting_seg = null
					_root_seg.detached_child = null
					_segs -= 1 
				
				max_extended_len = BASE_MAX_EXTENDED_LEN + extra_len + wind_extra_len
				
				# Retract if we've extended to the maximum possible length
				if _extended_len > max_extended_len and not ignore_extension_limit:
					begin_retracting()
			
			State.RETRACTING:
				if _segs <= base_segments:
					begin_inactive()
				else:
					if not _retracting_seg:
						_retracting_seg = _root_seg.get_child_seg()
						_root_seg.detached_child = _retracting_seg
						# Detach the pin joint of the root segment
						_root_seg.get_node("PinJoint2D").node_b = ""
						_retracting_seg.angular_damp = 0.0
						_retracting_seg.linear_damp = 0.0
					
					# Determine directions to propel Vines in for retraction
					var to_head_dir = _retracting_seg.position.direction_to(_root_seg.position)
					# Direction from root to the retracting seg's fifth child 
					var to_mid_vine_dir = _root_seg.position.direction_to(_retracting_seg.get_child_seg(5).position)
					
					const BASE_FORCE_STR = 135.0
					var force_str = BASE_FORCE_STR * force_mod
					var to_head_force = to_head_dir * force_str
					var to_mid_vine_force = to_mid_vine_dir * force_str
					
					#if _retracting_seg.global_position.distance_to(_root_seg.global_position) > 10.0:
						# FIXME creates multiple tweens
						#create_tween().tween_property(_retracting_seg, "global_position", _root_seg.global_position, 0.25) # .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
					# Propel retracting seg towards head
					_retracting_seg.apply_central_force(to_head_force)
					# Propel Vines after that towards head, slightly less
					_retracting_seg.get_child_seg().apply_central_force(to_head_force / 2)
					_retracting_seg.get_child_seg(1).apply_central_force(to_head_force / 2)
					# Propel root seg away from head and towards middle of vine  
					_root_seg.apply_central_force(to_head_force.rotated(PI) * 0.3 + to_mid_vine_force * 0.35)
					
					# Delete retracting seg if close to head, and pin to the next seg
					const MIN_DIST = 4.0
					if _retracting_seg.position.distance_to(_root_seg.position) < MIN_DIST:
						# Root seg pins to the Vine after the retracting seg
						_root_seg.get_node("PinJoint2D").node_b = _retracting_seg.get_child_seg().get_path()
						_retracting_seg.queue_free()
						_retracting_seg = null
						_root_seg.detached_child = null
						_segs -= 1 
					
					# Calculate ratio between number of extra segments and number of MAXIMUM extra segments
					# (how extended are we right now?)
					var extra_segs := _segs - base_segments
					var maximum_extra_segs = (BASE_MAX_EXTENDED_LEN + extra_len) / _len_per_seg 
					var extended_ratio = extra_segs / maximum_extra_segs
					
					# Invert it - how much have we retracted back to normal length?
					var retracted_ratio = 1 - extended_ratio
					
					# Lerp along this ratio 
					# Length that I'm able to extend by is from 0 to MAX_EXTENDED_LEN based on how much I've retracted
					_extended_len = extra_segs * _len_per_seg
		# Do dev right-click teleport
		if dev_mode and should_teleport:
			should_teleport = false
			_pot.global_position = get_global_mouse_position()
			position = _pot.global_position
			_pot.rotation = 0
			get_tree().set_group("vine", "global_position", _pot.global_position - Vector2(0, 10))
		
		_last_pos = pos

# Sometimes after extension or retraction there's an extra gap between the root seg (always fixed) 
# and the root seg's child (changes through retraction and extension).
# Removes this gap by detaching the child, teleporting it to the root, and reattaching it.
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
		
		# Only fix gap every 0.1 seconds
		await Timing.create_timer(self, 0.1)
		fixing_gap = false

# Adds a segment to the vine near the root.
# Takes the root seg's child and moves it down one segment length, then adds a 
#  new segment in the missing space.
func _add_seg():
	var child : Vine = _root_seg.get_child_seg()
	var new_child : Vine = vine_creator.create(child)
	
	# Place the child and new child with correct position and rotation
	var adj = Vector2(0, _len_per_seg).rotated(global_rotation)
	
	new_child.position = _root_seg.position + adj
	new_child._set_pos = new_child.position
	new_child.rotation = global_rotation
	new_child._set_rot = global_rotation
	
	child.position = _root_seg.position + adj * 2
	child._set_pos = child.position
	child.rotation = global_rotation
	child._set_rot = global_rotation
	
	$Vines.add_child(new_child)
	new_child.add_collision_exception_with(child) # Vines don't collide with each other
	new_child.make_self_exception()
	
	# Pin the new child to the root seg
	_root_seg.get_node("PinJoint2D").node_b = new_child.get_path()
	_segs += 1
	
	# Display sunlight vfx on child vine if root seg was on vfx cooldown
	if _root_seg.is_on_sunlight_vfx_cooldown():
		child.trigger_sunlight_vfx_chain()

# Gives the lightning buff, which speeds up movement for a set amount of length.
func _get_lightning_buff():
	if not _has_lightning_buff:
		_has_lightning_buff = true
		lightning_particles.emitting = true
		lightning_particles.amount = 20
		lightning_buff_amount = MAX_LIGHTNING_BUFF
		lightning_buff_display = MAX_LIGHTNING_BUFF
		lightning_speed_mod = LIGHTNING_SPEED
		
		# Don't emit both particles
		sun_particles.emitting = false
		
		# Tween the light attached to the head to grow, and tween electricity shader values
		if lightning_buff_tween:
			lightning_buff_tween.kill()
		lightning_buff_tween = create_tween().set_parallel()
		lightning_buff_tween.tween_property(storm_light, "texture_scale", 0.85, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_property(storm_light, "color", base, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_property(storm_light, "energy", 2.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		lightning_buff_tween.tween_method(_set_electricity, 1.5, 2.5, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		# Reapply the buff values
		lightning_buff_amount = MAX_LIGHTNING_BUFF
		lightning_buff_display = MAX_LIGHTNING_BUFF
		lightning_speed_mod = LIGHTNING_SPEED

# Updates the head's light and electricity values based on how much buff is left
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

# Removes lightning buff, dimming the light and removing electricity shader and particles
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

# Sets the value of the electricity shader.
func _set_electricity(val):
	_sprite.material.set_shader_parameter("electricity", max(val, 0.0))
	get_tree().call_group("vine", "_set_electricity", val)
	vine_line.material.set_shader_parameter("electricity", max(val, 0.0))

# Called when entering the wind beam. Creates particles and begins pushing the player in wind direction.
# Called repeatedly while in the wind beam, refreshing the buff's duration.
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

# Updates the wind direction based on the tower's lights.
func _update_wind_dir():
	const HALF_PI = PI / 2
	wind_direction = Vector2.from_angle(tower._lights.rotation + HALF_PI)

# Updates the windiness of the vine bar and calculates the updated wind direction.
func _update_wind_buff(delta):
	if has_wind_buff:
		_update_wind_dir()
		game.set_vine_windiness(wind_dot)
		if wind_buff_time_left > 0:
			wind_buff_time_left -= delta
		else:
			_remove_wind_buff()

# Removes windiness and wind beam effects.
func _remove_wind_buff():
	if has_wind_buff:
		has_wind_buff = false
		if wind_tween: wind_tween.kill()
		active_wind_beam_strength_mod = 0
		game.set_vine_windiness(0.0)

# Applies buffs based on weather.
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

# Teleports head and vine segments to the pot, fixing any issues with the head being stuck.
func unstuck():
	position = _pot.global_position
	get_tree().set_group("vine", "global_position", _pot.global_position - Vector2(0, 10))

#region Dash methods

## True when the player is able to dash, either after charging it up while INACTIVE or as a second-wind while RETRACTING.
## Becomes true when INACTIVE. Becomes false after a charged dash or second wind dash.
var can_dash := false

## True if the dash has been charged at all while INACTIVE. If this is true, the head will dash at the start of extension.
var should_dash_on_extend := false

## Float from 0.0 to 1.0 indicating how powerful the next charged dash will be. The second wind dash cannot be charged. 
var dash_charge_amount := 0.0

## A constant angle for the duration of the dash, indicating the direction the head is dashing in. 
## The player can turn slightly from this angle depending on dash strength. 
var dash_angle := 0.0

## Float from 0.0 to 1.0 indicating the strength of angular rotation of the head while dashing. 
## For charged dashes, this decreases as charge increases, to make powerful dashes less controllable.  
var dash_turn_strength := 0.0

## Float that constantly changes over the duration of a dash, indicating the current force that should be applied in the dash direction. 
var dash_force_strength := 0.0

## True if the player is currently dashing.
var is_dashing := false

func process_dash_logic(delta: float):
	if is_inactive() and can_dash:
		charge_dash_on_input(delta)
	update_dash_overlay()

## If the player can dash, is holding right click, is INACTIVE, and can extend, 
## increases dash charge amount and updates dash charge visuals.
## Triggers a dash on release of right click. 
func charge_dash_on_input(delta : float):
	if can_dash and is_inactive() and can_extend and Input.is_action_pressed("dash"):
		const DASH_CHARGE_DURATION = 1.0
		const DASH_CHARGE_MULTIPLIER = 1.0 / DASH_CHARGE_DURATION
		dash_charge_amount += delta * DASH_CHARGE_MULTIPLIER
		dash_charge_amount = clampf(dash_charge_amount, 0.0, 1.0)

	if can_dash and is_inactive() and can_extend and dash_charge_amount > 0 and not Input.is_action_pressed("dash"):
		begin_extending() # Triggers a dash

func update_dash_overlay():
	if dash_charge_amount > 0.0:
		dash_overlay.visible = true
		
		# Emit a particle if frame changes
		var current_dash_overlay_frame = dash_overlay.frame
		set_dash_overlay_anim_and_frame()
		var new_dash_overlay_frame = dash_overlay.frame
		if current_dash_overlay_frame != new_dash_overlay_frame:
			emit_dash_charge_particle(new_dash_overlay_frame)

func emit_dash_charge_particle(frame: int):
	const FRAMES = 8
	# -90 -> 0 -> 90 -> 180 as frames increase from 0 to 7
	var particle_angle = -PI / 2 + frame * (PI / 4) + rotation
	var particle_direction = Vector2.from_angle(particle_angle)
	
	const BASE_AMOUNT = 12
	const BASE_SPEED = 50.0
	var amount = BASE_AMOUNT + randi_range(0, 8)
	for i in range(amount):
		var rand_vel = particle_direction.rotated(randf_range(-PI / 8, PI / 8)) * BASE_SPEED * randf_range(0.8, 1.2)
		dash_charge_sparkles.emit_particle(Transform2D.IDENTITY, 
			rand_vel, Color.WHITE, Color.WHITE, GPUParticles2D.EmitFlags.EMIT_FLAG_VELOCITY)



func _wiggle_dash_overlay():
	var tween = create_tween().set_loops()
	const DUR = 0.33
	const OFFSET = Vector2(-0.25, -0.25)
	tween.tween_property(dash_overlay, "offset", OFFSET, DUR).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN)
	tween.tween_property(dash_overlay, "offset", Vector2.ZERO, DUR).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)


## Executes a dash, with varying behavior for charged and second wind dashes.
## Charged: Picks a dash direction and does an impulse in that direction. 
##          Overrides default extension movement to apply force in that direction depending on dash charge amount. 
##          The current force and turn rate allowance are tweened here.
## Second wind: Similar to charged, but a constant strength. Also begins extending for a bit. TODO
func dash() -> void:
	if is_extending(): # Must be a charged dash
		is_dashing = true
		can_dash = false
		dash_angle = get_mouse_angle()
		# Set head angle to dash angle
		_set_transform = Transform2D(dash_angle, get_transform().get_origin())
		
		var extra_dash_length = dash_charge_amount * 500.0
		extra_len += extra_dash_length # FIXME not using above value for limit
		
		const MAX_DASH_FORCE_STRENGTH = 200.0
		const MIN_DASH_FORCE_STRENGTH = 100.0
		var initial_dash_force_strength = MAX_DASH_FORCE_STRENGTH * pow(dash_charge_amount, 0.75) + MIN_DASH_FORCE_STRENGTH
		#initial_dash_force_strength = clampf(initial_dash_force_strength, MIN_DASH_FORCE_STRENGTH, MAX_DASH_FORCE_STRENGTH)
		
		dash_force_strength = initial_dash_force_strength
		
		var initial_dash_turn_strength = 1.0 - (dash_charge_amount * 0.6 + 0.2) # 0.2 control at full charge, 0.8 control at 0 charge
		dash_turn_strength = initial_dash_turn_strength
		
		var dash_duration = dash_charge_amount * 0.6 + 0.4
		
		var tween := create_tween()
		
		const SLOWDOWN_DUR = 0.2
		
		tween.tween_property(self, "dash_turn_strength", 1.0, dash_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(self, "dash_charge_amount", 0.0, dash_duration - 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "dash_force_strength", MIN_DASH_FORCE_STRENGTH * 0.75, dash_duration - SLOWDOWN_DUR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.chain().tween_property(self, "dash_force_strength", 0.0, SLOWDOWN_DUR).set_trans(Tween.TRANS_CUBIC)
		
		
		tween.tween_property(self, "is_dashing", false, 0.0)
		tween.tween_callback(begin_retracting)
		tween.tween_callback(dash_overlay.hide)
	elif is_retracting(): # Second wind dash
		# Second wind dash ignores limit because it's only for a short duration
		ignore_extension_limit = true
		is_dashing = true
		can_dash = false
		
		begin_extending()
		
		dash_angle = get_mouse_angle()
		# Set head angle to dash angle
		_set_transform = Transform2D(dash_angle, get_transform().get_origin())
		
		const SECOND_WIND_DASH_FORCE_STRENGTH_MIN = 50.0
		const SECOND_WIND_DASH_FORCE_STRENGTH_MAX = 200.0
		const SECOND_WIND_DASH_TURN_STRENGTH = 0.5
		const SECOND_WIND_DASH_DURATION = 0.5
		
		dash_force_strength = SECOND_WIND_DASH_FORCE_STRENGTH_MAX
		
		var tween := create_tween()
		tween.tween_property(self, "dash_force_strength", SECOND_WIND_DASH_FORCE_STRENGTH_MIN, SECOND_WIND_DASH_DURATION).set_trans(Tween.TRANS_CIRC)
		
		tween.tween_property(self, "is_dashing", false, 0.0)
		tween.tween_property(self, "ignore_extension_limit", false, 0.0)
		tween.tween_callback(begin_retracting)

func set_dash_overlay_anim_and_frame():
	var head_anim: String = _sprite.animation
	var head_frame: String = str(_sprite.frame)
	var dash_overlay_anim = "normal"
	if head_anim != "normal":
		dash_overlay_anim = head_anim + head_frame
	
	var dash_overlay_frame = int(dash_charge_amount * 7)
	
	dash_overlay.animation = dash_overlay_anim
	dash_overlay.frame = dash_overlay_frame

#endregion Dash methods

#region Camera offset

## Offsets the camera vertically in the direction of movement.
func _process_camera_offset(delta: float):
	if delta < 0.1:
		var dist_from_pot = global_position.y - _pot.global_position.y 
		#var dist_from_pot = linear_velocity.y
		#print(dist_from_pot)
		if abs(dist_from_pot) < 50: 
			dist_from_pot *= 0.0
		#elif abs(dist_from_pot) < 150:
			#dist_from_pot *= 0.5
		else:
			dist_from_pot *= -0.2
		const MAX_CAMERA_Y_OFFSET = 50.0
		target_y_offset = clamp(dist_from_pot, -MAX_CAMERA_Y_OFFSET, MAX_CAMERA_Y_OFFSET)
		var offset = camera_2d.offset.y
		offset = move_toward(offset, target_y_offset, delta * 10.0) * 0.5 + \
				lerpf(offset, target_y_offset, delta * 1.5) * 0.5 
		#camera_2d.offset.y = offset

#endregion Camera offset


#region Convenience helpers

func is_inactive() -> bool:
	return _state == State.INACTIVE

func is_extending() -> bool:
	return _state == State.EXTENDING

func is_retracting() -> bool:
	return _state == State.RETRACTING

func get_mouse_angle() -> float:
	return global_position.angle_to_point(get_global_mouse_position()) + PI/2
	
#endregion Convenience helpers


# Ensures that spiked and idle forms remain that way after playing once.
func _on_sprite_2d_animation_looped():
	if _sprite.animation == "spiked":
		_sprite.frame = 3
		_sprite.pause()
	elif _sprite.animation == "retract":
		_sprite.animation = "normal"

# Fixes being stuck.
func _on_stuck_timer_timeout():
	unstuck()

# Fixes being "dead".
func _on_dead_timer_timeout():
	unstuck()
