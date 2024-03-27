extends Node2D

class_name Main

@onready var _vines_bar : TextureProgressBar = $CanvasLayer/VinesBar
@onready var _sun_bar : TextureProgressBar = $CanvasLayer/SunBar
@onready var _lightning_bar : TextureProgressBar = $CanvasLayer/LightningBar
@onready var _head : FlowerHead = $FlowerHead
@onready var _cam : Camera2D = $FlowerHead/Camera2D
var hud_offset := Vector2(0,-50)
var win = false
var shake_strength = 0.0
const SHAKE_DECAY_RATE = 20.0
const RANDOM_SHAKE_STRENGTH = 30.0
var switch_bars_tween : Tween
# Called when the node enters the scene tree for the first time.

func _ready():
	_vines_bar.step = 0.001
	_sun_bar.step = 0.001
	_lightning_bar.step = 0.001
	_vines_bar.max_value = _head.BASE_MAX_EXTENDED_LEN
	_sun_bar.max_value = _head.BASE_MAX_EXTENDED_LEN
	_lightning_bar.max_value = _head.MAX_LIGHTNING_BUFF
	_vines_bar.value = 0.0
	_sun_bar.value = 0.0
	_lightning_bar.value = 0.0

func reset():
	get_tree().reload_current_scene()

func pause_game():
	await get_tree().create_timer(0.05).timeout
	get_tree().paused = true
	$PauseMenu.show()

func switch_to_lightning_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func switch_to_sun_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pause_game()

	if shake_strength:
		shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	# Set hud progress bar values
	if _head.can_extend:
		if _head.extra_len_display == 125.0:
			_sun_bar.value = 125.0
		const STR = 10.0
		var diff = abs(_head.vine_len_display - _vines_bar.value)
		_vines_bar.value = move_toward(_vines_bar.value, _head.vine_len_display, diff * STR * delta)
		diff = abs(_head.extra_len_display - _sun_bar.value)
		_sun_bar.value =move_toward(_sun_bar.value, _head.extra_len_display, diff * STR * delta)
		diff = abs(_head.lightning_buff_amount - _lightning_bar.value)
		_lightning_bar.value =move_toward(_lightning_bar.value, _head.lightning_buff_amount, diff * STR * 2.0 * delta)
	else: 
		if Input.is_action_just_pressed("extend"):
			shake()
	
	# Shake bar if necessary
	if shake_strength:
		$CanvasLayer.offset = get_random_offset()
	# Check for win
	if _head.position.y <= -2000.0:
		win = true
	if win:
		$CanvasLayer/Label.text = str($Stopwatch.time).pad_decimals(2)
		$CanvasLayer/Label.visible = true
		$Stopwatch.stop()

func shake():
	shake_strength = RANDOM_SHAKE_STRENGTH

func get_random_offset():
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)

