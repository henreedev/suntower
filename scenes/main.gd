extends Node2D

@onready var _vines_bar : TextureProgressBar = $CanvasLayer/VinesBar
@onready var _sun_bar : TextureProgressBar = $CanvasLayer/SunBar
@onready var _head : FlowerHead = $FlowerHead
@onready var _cam : Camera2D = $FlowerHead/Camera2D
var hud_offset := Vector2(0,-50)
var win = false
var shake_strength = 0.0
const SHAKE_DECAY_RATE = 20.0
const RANDOM_SHAKE_STRENGTH = 10.0
# Called when the node enters the scene tree for the first time.

func _ready():
	_vines_bar.step = 0.001
	_sun_bar.step = 0.001
	_vines_bar.max_value = _head.BASE_MAX_EXTENDED_LEN
	_sun_bar.max_value = _head.BASE_MAX_EXTENDED_LEN

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	# Set hud progress bar values
	if not (_head._state == FlowerHead.State.INACTIVE and not _head.can_extend):
		if _head.extra_len_display == 125.0:
			_sun_bar.value = 125.0
		const STR = 10.0
		var diff = abs(_head.vine_len_display - _vines_bar.value)
		_vines_bar.value = move_toward(_vines_bar.value, _head.vine_len_display, diff * STR * delta)
		diff = abs(_head.extra_len_display - _sun_bar.value)
		_sun_bar.value =move_toward(_sun_bar.value, _head.extra_len_display, diff * STR * delta)
	else: 
		if Input.is_action_just_pressed("extend"):
			shake()
	
	# Shake bar if necessary
	if shake_strength:
		$CanvasLayer.offset = get_random_offset()
	# Check for win
	if _head.position.y <= -1344.0:
		win = true
	if win:
		$CanvasLayer/Label.visible = true
		$CanvasLayer/Label.text = str($Stopwatch.time).pad_decimals(2)
		$Stopwatch.stop()

func shake():
	shake_strength = RANDOM_SHAKE_STRENGTH
	
func get_random_offset():
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
