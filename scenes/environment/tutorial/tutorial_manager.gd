extends Node2D
class_name TutorialManager

enum InscriptionType {LEFT_CLICK, FIRST_EXTENSION, FIRST_HOOK, HOLD_LEFT, HOLD_RIGHT, NONE}
var curr_inscription : InscriptionType = InscriptionType.NONE
var inscriptions : Array[TutorialInscription]

# up to 5 conds one step of the tutorial may need to satisfy
var satisfied_conds : Array[bool] = [false, false, false, false, false] 

@onready var first_extension_flower_marker : Marker2D = $FirstExtensionFlowerMarker
@onready var first_extension_pot_marker : Marker2D = $FirstExtensionPotMarker
@onready var first_hook_flower_marker : Marker2D = $FirstHookFlowerMarker
@onready var first_hook_pot_marker : Marker2D = $FirstHookPotMarker
@onready var hold_left_flower_marker : Marker2D = $HoldLeftFlowerMarker
@onready var hold_left_pot_marker : Marker2D = $HoldLeftPotMarker
@onready var hold_right_flower_marker : Marker2D = $HoldRightFlowerMarker
@onready var hold_right_pot_marker : Marker2D = $HoldRightPotMarker

@onready var flower_head : FlowerHead = get_tree().get_first_node_in_group("flowerhead")
@onready var pot : Player2 = get_tree().get_first_node_in_group("player2")


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is TutorialInscription:
			inscriptions.append(child)

func activate_first_inscription():
	curr_inscription = InscriptionType.LEFT_CLICK
	inscriptions[curr_inscription].activate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	_check_if_inscription_satisfied()

func _pos_within_radius(actual_pos : Vector2, target_pos : Vector2, radius : float):
	return actual_pos.distance_squared_to(target_pos) <= radius * radius

func _check_if_inscription_satisfied():
	const VALID_RADIUS = 8.0
	match curr_inscription:
		InscriptionType.LEFT_CLICK:
			# left clicked at all, and held left click long enough
			if satisfied_conds[0] and satisfied_conds[1]: 
				_satisfy_inscription()
		InscriptionType.FIRST_EXTENSION:
			# check if flower and pot are in correct spots
			if !satisfied_conds[0] and \
					_pos_within_radius(flower_head.global_position, first_extension_flower_marker.global_position, VALID_RADIUS):
				_satisfy_cond(0)
			if !satisfied_conds[1] and \
					_pos_within_radius(pot.global_position, first_extension_pot_marker.global_position, VALID_RADIUS) or \
					_pos_within_radius(pot.global_position, first_hook_pot_marker.global_position, VALID_RADIUS):
				_satisfy_cond(1)
			# flower pos correct, pot pos correct
			if satisfied_conds[0] and satisfied_conds[1]:
				_satisfy_inscription()
		InscriptionType.FIRST_HOOK:
			# check if flower and pot are in correct spots
			if !satisfied_conds[0] and \
					_pos_within_radius(flower_head.global_position, first_hook_flower_marker.global_position, VALID_RADIUS):
				_satisfy_cond(0)
			if !satisfied_conds[1] and \
					_pos_within_radius(pot.global_position, first_hook_pot_marker.global_position, VALID_RADIUS):
				_satisfy_cond(1)
			# flower pos correct, pot pos correct
			if satisfied_conds[0] and satisfied_conds[1]:
				_satisfy_inscription()
		InscriptionType.HOLD_LEFT:
			# check if flower and pot are in correct spots
			if !satisfied_conds[1] and \
					_pos_within_radius(flower_head.global_position, hold_left_flower_marker.global_position, VALID_RADIUS):
				_satisfy_cond(1)
			if !satisfied_conds[2] and \
					_pos_within_radius(pot.global_position, hold_left_pot_marker.global_position, VALID_RADIUS 	* 2):
				_satisfy_cond(2)
			# flower pos correct, pot pos correct
			if satisfied_conds[0] and satisfied_conds[1] and satisfied_conds[2]:
				_satisfy_inscription()
		InscriptionType.HOLD_RIGHT:
			# check if flower and pot are in correct spots
			if !satisfied_conds[1] and \
					_pos_within_radius(flower_head.global_position, hold_right_flower_marker.global_position, VALID_RADIUS):
				_satisfy_cond(1)
			if !satisfied_conds[2] and \
					_pos_within_radius(pot.global_position, hold_right_pot_marker.global_position, VALID_RADIUS * 2):
				_satisfy_cond(2)
			# flower pos correct, pot pos correct
			if satisfied_conds[0] and satisfied_conds[1] and satisfied_conds[2]:
				_satisfy_inscription()

func _clear_satisfied():
	for i in range(len(satisfied_conds)):
		satisfied_conds[i] = false

func _satisfy_cond(index : int):
	if not satisfied_conds[index]:
		satisfied_conds[index] = true
		var flash_tween = create_tween()
		flash_tween.tween_property(inscriptions[curr_inscription], "modulate", Color.WHITE * 1.5, 0.3).set_trans(Tween.TRANS_CUBIC)
		flash_tween.tween_property(inscriptions[curr_inscription], "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_CUBIC)
		# TODO play a sound

func _satisfy_inscription():
	inscriptions[curr_inscription].deactivate()
	curr_inscription = curr_inscription + 1
	if curr_inscription < len(inscriptions):
		inscriptions[curr_inscription].activate()
	else:
		_finish_tutorial()
	_clear_satisfied()

func _finish_tutorial():
	Values.finished_tutorial = true

func _input(event):
	match curr_inscription:
		InscriptionType.LEFT_CLICK:
			if event.is_action_pressed("extend"):
				_satisfy_cond(0)
			# check if player has extended at least 10 segments (they know to hold the button)
			if event.is_action_released("extend") and flower_head._segs > flower_head.base_segments + 10:
				_satisfy_cond(1)
		InscriptionType.HOLD_LEFT:
			if event.is_action_pressed("move_left") and flower_head._state == FlowerHead.State.RETRACTING:
				_satisfy_cond(0)
		InscriptionType.HOLD_RIGHT:
			if event.is_action_pressed("move_right") and flower_head._state == FlowerHead.State.RETRACTING:
				_satisfy_cond(0)
