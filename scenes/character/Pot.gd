extends RigidBody2D
class_name Pot

# Constants
# Vine root location (used in Head.gd to spawn the first segment)
const VINE_ROOT_OFFSET = Vector2(0, -4)

# Sounds on impact with map
const POT_HIT_SMALL = preload("res://assets/sound/sfx/PotHitSmall.wav")
const MEDIUM_BIG_HIT = preload("res://assets/sound/sfx/PotHitMediumBig.wav")
const MEDIUM_INTERMEDIATE_HIT = preload("res://assets/sound/sfx/PotHitMediumIntermediate.wav")
const BIG_HIT_WHOOSH = preload("res://assets/sound/sfx/PotHitWhoosh.wav")
const WEIRD_HIT = preload("res://assets/sound/sfx/PotHitWeird.wav")
const SMALL_HIT = preload("res://assets/sound/sfx/PotHitSmall2.wav")
const FAIL = preload("res://assets/sound/sfx/PotFail.wav")

# Variables to ensure certain sounds don't trigger too often
var small_hit_can_play = true
var medium_inter_hit_can_play = true

# Is the pot touching the map?
var touching = false

# Physics values from last physics update, for comparison on impacts
var prev_vel_sqrd : float
var prev_avel : float
var velocity_diff : float

## Duration the pot has not been touching the ground.
var air_time := 0.0 

# The offset from the center that the center of mass will always have.
const CENTER_OF_MASS_OFFSET = Vector2(0, 3)

# Audio variables
var stream : AudioStreamPolyphonic
var playback : AudioStreamPlaybackPolyphonic

# References to useful nodes
@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var scene_manager : SceneManager = get_tree().get_first_node_in_group("scenemanager")
@onready var sound_effect_player : AudioStreamPlayer2D = %SoundEffectPlayer
@onready var shadow : Sprite2D = $Pot/Shadow
@onready var sparks : GPUParticles2D = $Sparks
@onready var dirt : GPUParticles2D = $Dirt

# Called when the node enters the scene tree for the first time.
# Stores the audio stream to play SFX in.
func _ready():
	stream = sound_effect_player.stream

# Called every frame. 'delta' is the elapsed time since the previous frame.
# Displays the pot's shadow.
func _process(delta):
	_display_shadow()
	if not touching:
		air_time += delta

# Displays pot shadow only if pot is still, with a smooth fade in/out
func _display_shadow():
	const delta = 0.02
	if touching and abs(global_rotation) < delta and prev_vel_sqrd < 2.0:
		create_tween().tween_property(shadow, "modulate", Color(1, 1, 1, 1), 0.05)
	else:
		create_tween().tween_property(shadow, "modulate", Color(1, 1, 1, 0), 0.1)

# When entering the tree, get the SFX stream playback.
func _enter_tree():
	await Timing.create_timer(self, 0.05, true)
	playback = sound_effect_player.get_stream_playback()

# Called every physics update.
func _physics_process(delta):
	prev_vel_sqrd = linear_velocity.length_squared()
	prev_avel = angular_velocity
	center_of_mass = CENTER_OF_MASS_OFFSET.rotated(rotation) if touching else CENTER_OF_MASS_OFFSET
	# Make sure touching is never false when not moving at all (must be grounded)
	if not touching and head._state == Head.State.INACTIVE and \
			prev_vel_sqrd < 0.01 and abs(prev_avel) < 0.01:
		touching = true 

# Plays the given sound with the given volume offset, applying a random pitch modulation.
func _play_sound(sound, volume_offset := 0.0):
	if !playback: playback = sound_effect_player.get_stream_playback()
	var volume = _get_volume(sound) + volume_offset
	var rand_pitch = randf_range(0.8, 1.1)
	playback.play_stream(sound, 0, volume, rand_pitch)

# Returns volume offsets for each specific sound in decibels.
func _get_volume(sound):
	match sound:
		FAIL: return 20
		SMALL_HIT: return 10
		MEDIUM_BIG_HIT: return 3
		MEDIUM_INTERMEDIATE_HIT: return -2
		_: return 0

# Plays a sound and emits dirt and spark particles based on impact strength.
func _play_sound_on_impact(air_time : float):
	# Difference in velocity indicates the strength of the impact.
	velocity_diff = abs(prev_vel_sqrd - linear_velocity.length_squared())
	var adiff = abs(prev_avel - angular_velocity)
	
	# Should we spawn sparks on the left corner of the pot, or the right?
	# (-1, 0) if velocity is left relative to pot rotation, (1, 0) if to the right
	var left_or_right := Vector2(1 * ((int)(linear_velocity.rotated(rotation).x < 0) * 2 - 1), 0)
	
	# Adjust volume based on how hard the impact was
	var volume_offset := 0.0
	
	if not head._animating:
		# For each sound, if within its velocity diff range, play the sound and emit particles
		if velocity_diff > 60000.0 and air_time > 1.5:
			volume_offset = get_volume_adjust_by_speed(200000.0, 150000.0)
			_play_sound(FAIL, volume_offset)
			_play_sound(MEDIUM_BIG_HIT, volume_offset)
			_play_sound(BIG_HIT_WHOOSH, volume_offset)
			_emit_spark(randi_range(20, 35), left_or_right, true)
			_emit_dirt(randi_range(10, 15), left_or_right, true)
		elif velocity_diff > 50000.0:
			volume_offset = get_volume_adjust_by_speed(150000.0, 50000.0)
			_play_sound(MEDIUM_BIG_HIT, volume_offset)
			_emit_spark(randi_range(7, 13), left_or_right, true)
			_emit_dirt(randi_range(5, 10), left_or_right, true)
		elif velocity_diff > 10000.0:
			if medium_inter_hit_can_play:
				volume_offset = get_volume_adjust_by_speed(50000.0, 10000.0)
				_play_sound(MEDIUM_INTERMEDIATE_HIT, volume_offset)
				_emit_dirt(randi_range(3, 7), left_or_right)
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

# Calculates a volume offset based on where velocity diff lies within the sound's bounds 
func get_volume_adjust_by_speed(upper : float, lower : float):
	const MIN_DB = -1.0
	const MAX_DB = 2.0 
	
	var bounds_diff = upper - lower
	var volume_adjust = lerpf(MIN_DB, MAX_DB, (velocity_diff - lower) / bounds_diff)
	return clampf(volume_adjust, MIN_DB, MAX_DB)

# Emits a certain amount of sparks in a certain direction, or to both sides of the pot. 
# Randomly varies particle motion values. 
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

# Emits a certain amount of dirt in a certain direction, or to both sides of the pot. 
# Randomly varies particle motion values. 
func _emit_dirt(amount : int, dir : Vector2, both_sides = false):
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
		dirt.emit_particle(Transform2D(0, Vector2.ONE, 0, spark_origin), 
			rand_vel, Color.WHITE, Color.WHITE, 5)


func _on_body_entered(body):
	if body.is_in_group("tower_hitbox"):
		touching = true
		_play_sound_on_impact(air_time)
		air_time = 0.0

func _on_body_exited(body):
	if body.is_in_group("tower_hitbox"):
		touching = false
