extends Node2D
@onready var head = $"../.."
@export var follow_x := false
@export var follow_y := true

# Called when the node enters the scene tree for the first time.
func _ready():
	if not follow_x:
		global_position.x = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if follow_x: 
		global_position.x = head.global_position.x
	if follow_y:
		global_position.y = head.global_position.y
