extends Node2D

@onready var _hud : TextureProgressBar = $HUD/TextureProgressBar 
@onready var _head : FlowerHead = $FlowerHead
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_hud.max_value = _head.max_extended_len
	_hud.value = _hud.max_value - _head._extended_len if _head.can_extend else 0
