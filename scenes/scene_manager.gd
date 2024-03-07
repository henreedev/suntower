extends Node2D

@export var game_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_menu_game_started():
	$TransitionOverlay/AnimationPlayer.play("fade_to_black")


func _on_transition_overlay_transitioned():
	$CurrentScene.get_child(0).queue_free()
	$CurrentScene.add_child(game_scene.instantiate())
