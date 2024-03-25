extends Node
class_name Stopwatch

var time = 0.0
var running = false

func get_time():
	return time

func stop():
	running = false

func start():
	running = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if running: time += delta
