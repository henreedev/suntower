extends RigidBody2D

class_name Hat

## Hat type enum.
enum Type {
	BEANIE,
}

var type : Type

## Whether this hat is currently worn or not.
var wearing := false

## Whether this hat can be picked up by the Head.
var wearable := true

## Vector2. Set this to instantly teleport to this position.
var _set_pos 

## float. Set this to instantly rotate to this angle.
var _set_rot 

## Direction to fling this hat in (left or right). Swaps with each hat, allowing for juggling.
static var eject_right := true

@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var asprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

## Attaches this hat to the Head, disabling physics.
func wear():
	# Swap hat ownership
	var curr_hat = get_head_hat()
	if curr_hat:
		curr_hat.eject()
	reparent(head, true)
	
	# Set state
	wearing = true
	freeze = true
	
	# Move onto Head in fun way
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Make sound
	pickup_sound.play()

## Removes this hat from the Head, enabling physics and flinging it up in the air.
func eject():
	reparent(Game.instance, false)
	wearing = false
	global_position = head.global_position
	global_rotation = head.global_rotation
	_set_pos = head.global_position
	_set_rot = head.global_rotation
	freeze = false
	
	become_unwearable()
	create_tween().tween_callback(become_wearable).set_delay(0.5)
	
	var hoz_impulse = (int(eject_right) * 2 - 1) * 30 * randf_range(0.8, 1.2)
	eject_right = not eject_right
	apply_impulse(Vector2(hoz_impulse, -200))
	apply_torque_impulse(randf_range(-1, 1))

## PROCESS

func _process(delta: float) -> void:
	if wearing:
		match type:
			Type.BEANIE:
				var local_vel = head.linear_velocity.rotated(head.global_rotation)
				# Show vertical spinning at correct speed
				var speed = abs(local_vel.y)
				if speed > 75:
					asprite.play("beanie_spin")
					asprite.sprite_frames.set_animation_speed("beanie_spin", speed / 10.0)
				else:
					if asprite.animation == "beanie_spin":
						asprite.play("beanie_left")
					const FLIP_SPEED = 50.0
					# Adjust left/right direction 
					if local_vel.x < -FLIP_SPEED:
						asprite.play("beanie_left")
					elif local_vel.x > FLIP_SPEED:
						asprite.play("beanie_right")


## HELPERS


func get_head_hat() -> Hat:
	for child in head.get_children():
		if child is Hat:
			return child
	return null

func become_wearable():
	wearable = true
	collision_mask = 1 + 16 # Collide with Head

func become_unwearable():
	wearable = false
	collision_mask = 1
	match type:
		Type.BEANIE:
			asprite.play("beanie_right")


## SILLY TELEPORTATION STUFF FOR RIGIDBODY2D

func _integrate_forces(state):
	if _set_pos:
		state.transform = Transform2D(state.transform.get_rotation(), _set_pos)
		_set_pos = null
	if _set_rot:
		state.transform = Transform2D(_set_rot, state.transform.get_origin())
		_set_rot = null


func _on_body_entered(body: Node) -> void:
	if body is Head and wearable:
		wear.call_deferred()
