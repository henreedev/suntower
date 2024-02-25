extends Node2D

@onready var _hud : TextureProgressBar = $HUD/TextureProgressBar 
@onready var _head : FlowerHead = $FlowerHead
@onready var _cam : Camera2D = $FlowerHead/Camera2D
var hud_offset := Vector2(0,-50)
# Called when the node enters the scene tree for the first time.

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_hud.step = 0.01
	_hud.max_value = _head.BASE_MAX_EXTENDED_LEN * 2
	_hud.value = _head.max_extended_len - _head._extended_len if _head._state == FlowerHead.State.EXTENDING or _head.can_extend else 0
	_hud.position = _cam.get_target_position() + hud_offset
