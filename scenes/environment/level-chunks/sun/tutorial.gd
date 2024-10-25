extends Node2D
class_name Tutorial
@onready var tutorial_manager = $TutorialManager

func start_tutorial():
	if not Values.skip_cutscene and \
			not Values.victory_count > 0:
		tutorial_manager.activate_first_inscription()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
