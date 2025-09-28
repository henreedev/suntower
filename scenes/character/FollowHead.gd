extends Node2D
@onready var head : Head = get_tree().get_first_node_in_group("flowerhead")
@export var follow_x := false
@export var follow_y := true
@export var follow_rotation := false
## Overrides follow_rotation
@export var follow_mouse_rotation := false

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
	if follow_rotation:
		global_rotation = head.global_rotation
	if follow_mouse_rotation:
		const HALF_PI = PI / 2.0
		var mouse_angle = (get_global_mouse_position() - global_position).angle() + HALF_PI
		global_rotation = mouse_angle
