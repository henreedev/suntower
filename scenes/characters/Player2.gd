extends RigidBody2D
class_name Player2

const FLOWER_HEIGHT = 320
const vine_root_offset = Vector2(0, -4)

var small_hit_can_play = true
var touching = false
var prev_vel_sqrd : float
var prev_avel : float
@onready var _head : FlowerHead = get_tree().get_first_node_in_group("flowerhead")
@onready var scene_manager : SceneManager = get_tree().get_first_node_in_group("scenemanager")
@onready var medium_hit : AudioStreamPlayer2D = $Sound/MediumHit1
@onready var medium_big_hit : AudioStreamPlayer2D = $Sound/MediumBigHit1
@onready var medium_inter_hit : AudioStreamPlayer2D = $Sound/MediumInterHit1
@onready var big_hit_whoosh : AudioStreamPlayer2D = $Sound/BigHitWhoosh
@onready var weird_hit : AudioStreamPlayer2D = $Sound/WeirdHit
@onready var small_hit : AudioStreamPlayer2D = $Sound/SmallHit
@onready var fail : AudioStreamPlayer2D = $Sound/Fail
@onready var shadow : Sprite2D = $Smoothing2D/Pot/Shadow
@onready var sparks : GPUParticles2D = $Sparks
@onready var dust : GPUParticles2D = $Dust
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_check_inputs()
	_act_on_state(_head._state)
	_display_shadow()

func _display_shadow():
	const delta = 0.02
	if touching and abs(global_rotation) < delta and linear_velocity.length_squared() < 2.0:
		create_tween().tween_property(shadow, "modulate", Color(1, 1, 1, 1), 0.05)
	else:
		create_tween().tween_property(shadow, "modulate", Color(1, 1, 1, 0), 0.1)

func set_volume(db):
	fail.volume_db = SceneManager.sound_volume + SceneManager.sound_volume_offset_unnormalized
	small_hit.volume_db = SceneManager.sound_volume + SceneManager.sound_volume_offset_unnormalized
	medium_hit.volume_db = db
	medium_big_hit.volume_db = db + SceneManager.sfx_bighit_adj
	medium_inter_hit.volume_db = db
	big_hit_whoosh.volume_db = db
	weird_hit.volume_db = db


func _act_on_state(state : FlowerHead.State):
	match state:
		FlowerHead.State.EXTENDING:
			linear_damp = 250.0
			angular_damp = 10
		FlowerHead.State.RETRACTING:
			linear_damp = 1.0
			angular_damp = 2
		FlowerHead.State.INACTIVE:
			pass

func _check_inputs():
	if Input.is_action_just_pressed("extend"):
		_head.begin_extending()

func _physics_process(delta):
	prev_vel_sqrd = linear_velocity.length_squared()
	prev_avel = angular_velocity
	# Make sure touching is never false when not moving at all (must be grounded)
	if not touching and _head._state == FlowerHead.State.INACTIVE and \
			prev_vel_sqrd < 0.01 and abs(prev_avel) < 0.01:
		touching = true 

func _play_sound():
	var diff = abs(prev_vel_sqrd - linear_velocity.length_squared())
	var adiff = abs(prev_avel - angular_velocity)
	var rand_pitch = randf_range(0.8, 1.1)
	#var left_or_right := Vector2(1 * ((int)(randf() > 0.5) * 2 - 1), 0)
	print(linear_velocity.rotated(rotation).x)
	var left_or_right := Vector2(1 * ((int)(linear_velocity.rotated(rotation).x < 0) * 2 - 1), 0)
	if not _head._animating:
		#_emit_dust(10, left_or_right)
		if diff > 150000.0:
			fail.play()
			medium_big_hit.pitch_scale = rand_pitch
			medium_big_hit.play()
			big_hit_whoosh.play()
			_emit_spark(30, left_or_right, true)
			_emit_dust(30, left_or_right, true)
		elif diff > 50000.0:
			medium_hit.pitch_scale = rand_pitch
			medium_hit.play()
			_emit_spark(10, left_or_right, true)
			_emit_dust(10, left_or_right, true)
		elif diff > 10000.0:
			medium_inter_hit.pitch_scale = rand_pitch
			medium_inter_hit.play()
			_emit_dust(4, left_or_right)
		elif diff > 500.0 or adiff > 3.0:
			if small_hit_can_play:
				small_hit.pitch_scale = rand_pitch
				small_hit.play()
				small_hit_can_play = false
				_emit_spark(2, left_or_right)
				await get_tree().create_timer(0.5).timeout
				small_hit_can_play = true
			pass

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
		var spark_origin = global_position + dir * SIDE_LENGTH + Vector2(0, BOTTOM_HEIGHT)
		var rand_vel := ((upward_vel + hoz_vel) * randf_range(0.4, 0.8)).rotated(randf_range(-0.5, 0.5))
		dust.emit_particle(Transform2D(0, Vector2.ONE, 0, spark_origin), 
			rand_vel, Color.WHITE, Color.WHITE, 5)

func _on_body_entered(body):
	if body.is_in_group("tower_hitbox"):
		touching = true
		_play_sound()

func _on_body_exited(body):
	if body.is_in_group("tower_hitbox"):
		touching = false
