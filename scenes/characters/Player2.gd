extends RigidBody2D
class_name Player2

const FLOWER_HEIGHT = 32

@onready var _head : FlowerHead = $N/FlowerHead

# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(0.1).timeout
	_head.position = position + Vector2(0, -FLOWER_HEIGHT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_check_inputs()

func _check_inputs():
	if Input.is_action_just_pressed("extend"):
		_head.begin_extending()
		
	
