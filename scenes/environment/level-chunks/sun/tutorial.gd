extends Node2D
class_name Tutorial
@onready var tutorial_manager = $TutorialManager

func start_tutorial():
	#if not Values.skip_cutscene and \
			#not Values.victory_count > 0:
	tutorial_manager.activate_first_inscription()
