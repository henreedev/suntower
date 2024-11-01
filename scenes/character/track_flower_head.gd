extends Node2D
@onready var flower_head = $"../.."


# Called when the node enters the scene tree for the first time.
func _ready():
	global_position.x = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.y = flower_head.global_position.y
