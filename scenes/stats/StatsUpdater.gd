extends Node

@onready var main : Game = $".."
@onready var tower : Tower = $"../Tower"
@onready var player : Head = $"../Head"

# update height at interval
const UPDATE_INTERVAL = 0.5
var update_time_left = 0.0

# autosave at interval
const AUTOSAVE_INTERVAL = 30.0
var autosave_time_left = AUTOSAVE_INTERVAL


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player._animating:
		Values.increment_time(delta)
		_process_autosave(delta)
		_process_height_update(delta)

func _process_autosave(delta):
	if autosave_time_left > 0:
		autosave_time_left -= delta
	else:
		Values.save_user_data()
		autosave_time_left = AUTOSAVE_INTERVAL

func _process_height_update(delta):
	if not Values.won:
		Values.update_height(player.get_height())
