extends Node2D
class_name Tutorial
@onready var tutorial_manager = $TutorialManager

func start_tutorial():
	if not Values.finished_tutorial:
		tutorial_manager.activate_first_inscription()
