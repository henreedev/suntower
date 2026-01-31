extends Node2D

## Contains logic for entering and exiting checkpoints, which are lore intermissions between sections.
## Also contains camera limiting / zooming logic.
class_name Checkpoint


var player_in_checkpoint := false
var player_in_exit_area := false

@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var entrance_teleport_marker: Marker2D = %EntranceTeleportMarker
@onready var game : Game = get_tree().get_first_node_in_group("game")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_checkpoint:
			if player_in_exit_area:
				# TODO ask for confirmation if no upgrade chosen
				exit_checkpoint()
			else:
				enter_checkpoint(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Can enter from top or bottom.
## fades screen to black and 
## pulls Head to entrance position.
## And zooms in screen. 
## Then teleports flower and vines and pot to entrance position 
## and gives them upward impulse, 
## closing floor hitbox, 
## fading in screen from black. 

func enter_checkpoint(from_bottom: bool) -> void:
	assert( not player_in_checkpoint )
	player_in_checkpoint = true
	
	var tween := create_tween()
	if from_bottom:
		game.fade_screen()
		head.queue_teleport(entrance_teleport_marker.global_position)
		

func exit_checkpoint() -> void:
	pass


func _on_entrance_area_body_entered(body: Node2D) -> void:
	if not player_in_checkpoint and body is Head or body is Pot:
		enter_checkpoint(true)

var exit_bodies_inside: Array[RigidBody2D]
func _on_exit_area_body_entered(body: Node2D) -> void:
	if body is Head or body is Pot:
		exit_bodies_inside.append(body)
	if not exit_bodies_inside.is_empty():
		player_in_exit_area = true


func _on_exit_area_body_exited(body: Node2D) -> void:
	if body is Head or body is Pot:
		exit_bodies_inside.erase(body)
	if exit_bodies_inside.is_empty():
		player_in_exit_area = false
