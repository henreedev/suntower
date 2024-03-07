extends Node
class_name Stopwatch

var time = 0.0
var running = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_time():
	return time

func stop():
	running = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if running: time += delta
