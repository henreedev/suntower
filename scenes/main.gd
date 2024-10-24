extends Node2D

class_name Main

var hud_offset := Vector2(0,-50)
var shake_strength = 0.0
const SHAKE_DECAY_RATE = 20.0
const RANDOM_SHAKE_STRENGTH = 30.0
var switch_bars_tween : Tween

@onready var _vines_bar : TextureProgressBar = $CanvasLayer/VinesBar
@onready var _sun_bar : TextureProgressBar = $CanvasLayer/SunBar
@onready var _lightning_bar : TextureProgressBar = $CanvasLayer/LightningBar
@onready var _wind_bar : TextureProgressBar = $CanvasLayer/WindBar
@onready var flower_head : FlowerHead = $FlowerHead
@onready var _cam : Camera2D = $FlowerHead/Camera2D
@onready var pause_menu = $PauseMenu
@onready var color_rect : ColorRect = $CanvasLayer/ColorRect

func _ready():
	_vines_bar.max_value = flower_head.BASE_MAX_EXTENDED_LEN
	_sun_bar.max_value = flower_head.BASE_MAX_EXTENDED_LEN
	_lightning_bar.max_value = flower_head.MAX_LIGHTNING_BUFF
	_wind_bar.max_value = flower_head.BASE_MAX_EXTENDED_LEN
	_vines_bar.value = 0.0
	_sun_bar.value = 0.0
	_lightning_bar.value = 0.0
	_wind_bar.value = flower_head.BASE_MAX_EXTENDED_LEN

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not pause_menu.just_unpaused:
		pause()

func pause():
	if not get_tree().paused:
		get_tree().paused = true
		pause_menu.options_menu.refresh()
		pause_menu.show()
	SceneManager.instance.reduce_music_volume()

func switch_to_lightning_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func switch_to_wind_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func switch_to_sun_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
func switch_to_no_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -50.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -50.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func set_vine_windiness(windiness : float):
	_vines_bar.material.set_shader_parameter("windiness", windiness)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shake_strength:
		shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	# Set hud progress bar values
	if flower_head.can_extend:
		if flower_head.extra_len_display == flower_head.BASE_MAX_EXTENDED_LEN:
			_sun_bar.value = flower_head.BASE_MAX_EXTENDED_LEN
		const STR = 10.0
		var diff 
		diff = abs(flower_head.vine_len_display - _vines_bar.value)
		_vines_bar.value = move_toward(_vines_bar.value, flower_head.vine_len_display, diff * STR * delta)
		diff = abs(flower_head.extra_len_display - _sun_bar.value)
		_sun_bar.value =move_toward(_sun_bar.value, flower_head.extra_len_display, diff * STR * delta)
		diff = abs(flower_head.lightning_buff_amount - _lightning_bar.value)
		_lightning_bar.value =move_toward(_lightning_bar.value, flower_head.lightning_buff_amount, diff * STR * 2.0 * delta)
		diff = abs(flower_head.wind_extra_len_display - _wind_bar.value)
		_wind_bar.value =move_toward(_wind_bar.value, flower_head.wind_extra_len_display, diff * STR * delta)
	else: 
		if Input.is_action_just_pressed("extend"):
			shake()
	
	# Shake bar if necessary
	if shake_strength:
		$CanvasLayer.offset = get_random_offset()

func shake():
	shake_strength = RANDOM_SHAKE_STRENGTH

func get_random_offset():
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
