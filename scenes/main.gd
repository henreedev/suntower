extends Node2D

@onready var _vines_bar : TextureProgressBar = $CanvasLayer/VinesBar
@onready var _sun_bar : TextureProgressBar = $CanvasLayer/SunBar
@onready var _head : FlowerHead = $FlowerHead
@onready var _cam : Camera2D = $FlowerHead/Camera2D
var hud_offset := Vector2(0,-50)
# Called when the node enters the scene tree for the first time.

func _ready():
	pass # Replace with function body.
	_vines_bar.step = 1.0
	_sun_bar.step = 1.0
	_vines_bar.max_value = _head.BASE_MAX_EXTENDED_LEN
	_sun_bar.max_value = _head.BASE_MAX_EXTENDED_LEN

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _head.vine_len_display == 125.0:
		_vines_bar.value = 125.0
	if _head.extra_len_display == 125.0:
		_sun_bar.value = 125.0
	const STR = 25.0
	var diff = abs(_head.vine_len_display - _vines_bar.value)
	_vines_bar.value = move_toward(_vines_bar.value, _head.vine_len_display, diff * STR * delta)
	diff = abs(_head.extra_len_display - _sun_bar.value)
	_sun_bar.value =move_toward(_sun_bar.value, _head.extra_len_display, diff * STR * delta)
	
	#_vines_bar.value = _head.vine_len_display
	#_sun_bar.value = _head.extra_len_display
