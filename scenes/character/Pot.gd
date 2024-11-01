extends RigidBody2D
class_name Pot

const vine_root_offset = Vector2(0, -4)


const POT_HIT_SMALL = preload("res://assets/sound/sfx/PotHitSmall2.wav")
const MEDIUM_BIG_HIT = preload("res://assets/sound/sfx/PotHitMediumBig.wav")
const MEDIUM_INTERMEDIATE_HIT = preload("res://assets/sound/sfx/PotHitMediumIntermediate.wav")
const BIG_HIT_WHOOSH = preload("res://assets/sound/sfx/PotHitWhoosh.wav")
const WEIRD_HIT = preload("res://assets/sound/sfx/PotHitWeird.wav")
const SMALL_HIT = preload("res://assets/sound/sfx/PotHitSmall.wav")
const FAIL = preload("res://assets/sound/sfx/PotFail.wav")

var small_hit_can_play = true
var medium_inter_hit_can_play = true
var touching = false
var prev_vel_sqrd : float
var prev_avel : float
var velocity_diff : float

var stream : AudioStreamPolyphonic
var playback : AudioStreamPlaybackPolyphonic

@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var scene_manager : SceneManager = get_tree().get_first_node_in_group("scenemanager")
@onready var sound_effect_player : AudioStreamPlayer2D = %SoundEffectPlayer
@onready var shadow : Sprite2D = $Smoothing2D/Pot/Shadow
@onready var sparks : GPUParticles2D = $Sparks
@onready var dust : GPUParticles2D = $Dust

# Called when the node enters the scene tree for the first time.
func _ready():
	stream = sound_effect_player.stream
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_check_inputs()
	_act_on_state(head._state)
	_display_shadow()

func _display_shadow():
	const delta = 0.02
	if touching and abs(global_rotation) < delta and prev_vel_sqrd < 2.0:
		create_tween().tween_property(shadow, "modulate", Color(1, 1, 1, 1), 0.05)
	else:
		create_tween().tween_property(shadow, "modulate", Color(1, 1, 1, 0), 0.1)

func _enter_tree():
	await Timing.create_timer(self, 0.05, true)
	playback = sound_effect_player.get_stream_playback()

func _act_on_state(state : Head.State):
	match state:
		Head.State.EXTENDING:
			linear_damp = 250.0
			angular_damp = 10
		Head.State.RETRACTING:
			linear_damp = 1.0
			angular_damp = 2
		Head.State.INACTIVE:
			linear_damp = 1.03

func _check_inputs():
	if Input.is_action_just_pressed("extend"):
		head.begin_extending()

func _physics_process(delta):
	prev_vel_sqrd = linear_velocity.length_squared()
	prev_avel = angular_velocity
	# Make sure touching is never false when not moving at all (must be grounded)
	if not touching and head._state == Head.State.INACTIVE and \
			prev_vel_sqrd < 0.01 and abs(prev_avel) < 0.01:
		touching = true 

func _play_sound(sound, volume_offset := 0.0):
	if !playback: playback = sound_effect_player.get_stream_playback()
	var volume = _get_volume(sound) + volume_offset
	var rand_pitch = randf_range(0.8, 1.1)
	playback.play_stream(sound, 0, volume, rand_pitch)

func _get_volume(sound):
	match sound:
		FAIL: return 20
		SMALL_HIT: return 10
		MEDIUM_BIG_HIT: return 3
		_: return 0

func _play_sound_on_impact():
	velocity_diff = abs(prev_vel_sqrd - linear_velocity.length_squared())
	var adiff = abs(prev_avel - angular_velocity)
	var rand_pitch = randf_range(0.8, 1.1)
	var left_or_right := Vector2(1 * ((int)(linear_velocity.rotated(rotation).x < 0) * 2 - 1), 0)
	var volume_offset := 0.0
	if not head._animating:
		if velocity_diff > 150000.0:
			volume_offset = get_volume_adjust_by_speed(200000.0, 150000.0)
			_play_sound(FAIL, volume_offset)
			_play_sound(MEDIUM_BIG_HIT, volume_offset)
			_play_sound(BIG_HIT_WHOOSH, volume_offset)
			_emit_spark(randi_range(20, 35), left_or_right, true)
			_emit_dust(randi_range(10, 15), left_or_right, true)
		elif velocity_diff > 50000.0:
			volume_offset = get_volume_adjust_by_speed(150000.0, 50000.0)
			_play_sound(MEDIUM_BIG_HIT, volume_offset)
			_emit_spark(randi_range(7, 13), left_or_right, true)
			_emit_dust(randi_range(5, 10), left_or_right, true)
		elif velocity_diff > 10000.0:
			if medium_inter_hit_can_play:
				volume_offset = get_volume_adjust_by_speed(50000.0, 10000.0)
				_play_sound(MEDIUM_INTERMEDIATE_HIT, volume_offset)
				_emit_dust(randi_range(3, 7), left_or_right)
				medium_inter_hit_can_play = false
				await Timing.create_timer(self, 0.2)
				medium_inter_hit_can_play = true
		elif velocity_diff > 500.0 or adiff > 3.0:
			if small_hit_can_play:
				volume_offset = get_volume_adjust_by_speed(10000.0, 500.0)
				_play_sound(SMALL_HIT, volume_offset)
				_emit_spark(randi_range(1, 3), left_or_right)
				small_hit_can_play = false
				await Timing.create_timer(self, 0.5)
				small_hit_can_play = true

func get_volume_adjust_by_speed(upper : float, lower : float):
	const MIN_DB = -4.0
	const MAX_DB = 4.0 
	
	var bounds_diff = upper - lower
	var volume_adjust = lerpf(MIN_DB, MAX_DB, (velocity_diff - lower) / bounds_diff)
	return clampf(volume_adjust, MIN_DB, MAX_DB)

func _emit_spark(amount : int, dir : Vector2, both_sides = false):
	const BOTTOM_HEIGHT = 5.5
	const SIDE_LENGTH = 5
	const UP_SPEED = 100.0
	const SPEED = 100.0
	var upward_vel := Vector2.UP * UP_SPEED * randf_range(0.5, 1.0)
	var hoz_vel := (Vector2(dir.x * SPEED, 0).rotated(rotation) + Vector2(linear_velocity.x * 0.5, 0)) * randf_range(0.8, 1.0)
	for i in range(amount):
		if both_sides: hoz_vel *= Vector2.LEFT
		if both_sides: dir *= Vector2.LEFT
		var spark_origin = global_position + dir * SIDE_LENGTH + Vector2(0, BOTTOM_HEIGHT)
		var rand_vel := ((upward_vel + hoz_vel) * randf_range(0.4, 1.2)).rotated(randf_range(-0.5, 0.5))
		sparks.emit_particle(Transform2D(0, Vector2.ONE, 0, spark_origin), 
			rand_vel, Color.WHITE, Color.WHITE, 5)

func _emit_dust(amount : int, dir : Vector2, both_sides = false):
	const BOTTOM_HEIGHT = 5.5
	const SIDE_LENGTH = 5
	const UP_SPEED = 100.0
	const SPEED = 100.0
	var upward_vel := Vector2.UP * UP_SPEED * randf_range(0.5, 1.0)
	var hoz_vel := (Vector2(dir.x * SPEED, 0).rotated(rotation) + Vector2(linear_velocity.x * 0.5, 0)) * randf_range(0.8, 1.0)
	for i in range(amount):
		if both_sides: hoz_vel *= Vector2.LEFT
		if both_sides: dir *= Vector2.LEFT
		var spark_origin = global_position + Vector2(0, -3)
		var rand_vel := ((upward_vel + hoz_vel) * randf_range(0.4, 0.8)).rotated(randf_range(-0.5, 0.5))
		dust.emit_particle(Transform2D(0, Vector2.ONE, 0, spark_origin), 
			rand_vel, Color.WHITE, Color.WHITE, 5)

func _on_body_entered(body):
	if body.is_in_group("tower_hitbox"):
		touching = true
		_play_sound_on_impact()

func _on_body_exited(body):
	if body.is_in_group("tower_hitbox"):
		touching = false