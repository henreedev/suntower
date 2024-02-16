extends RigidBody2D
class_name Player2

const FLOWER_HEIGHT = 320
const vine_root_offset = Vector2(0, -4)

@onready var _head : FlowerHead = get_tree().get_first_node_in_group("flowerhead")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_check_inputs()

func _check_inputs():
	if Input.is_action_just_pressed("extend"):
		_head.begin_extending()

func _on_bg_music_finished():
	$Sound/BGMusic.play()
