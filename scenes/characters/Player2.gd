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
		create_tween().tween_property($Pot/Shadow, "modulate", Color(1, 1, 1, 1), 0.05)
	else:
		create_tween().tween_property($Pot/Shadow, "modulate", Color(1, 1, 1, 0), 0.1)

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

func _play_sound():
	var diff = abs(prev_vel_sqrd - linear_velocity.length_squared())
	var adiff = abs(prev_avel - angular_velocity)
	if not _head._animating:
		if diff > 150000.0:
			fail.play()
			medium_big_hit.play()
			big_hit_whoosh.play()
		elif diff > 100000.0:
			medium_hit.play()
		elif diff > 50000.0:
			medium_hit.play()
		elif diff > 10000.0:
			medium_inter_hit.play()
		elif diff > 500.0 or adiff > 3.0:
			if small_hit_can_play:
				small_hit.play()
				small_hit_can_play = false
				await get_tree().create_timer(0.5).timeout
				small_hit_can_play = true
			pass

func _on_body_entered(body):
	if body.is_in_group("tower"):
		touching = true
		_play_sound()

func _on_body_exited(body):
	if body.is_in_group("tower"):
		touching = false
