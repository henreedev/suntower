extends Node2D

class_name Main

signal initialized 
var is_initialized := false

static var instance : Main

var hud_offset := Vector2(0,-50)
var shake_strength = 0.0
const SHAKE_DECAY_RATE = 200.0
const RANDOM_SHAKE_STRENGTH = 30.0
var switch_bars_tween : Tween

@onready var _vines_bar : TextureProgressBar = $CanvasLayer/VinesBar
@onready var _sun_bar : TextureProgressBar = $CanvasLayer/SunBar
@onready var _lightning_bar : TextureProgressBar = $CanvasLayer/LightningBar
@onready var _wind_bar : TextureProgressBar = $CanvasLayer/WindBar
@onready var head : Head = $Head
@onready var _cam : Camera2D = $Head/Camera2D
@onready var pause_menu = $PauseMenu
@onready var color_rect : ColorRect = $CanvasLayer/ColorRect
@onready var time_trackers : Array[TimeTracker] = [%SunTime, %StormTime, %WindTime, %PeacefulTime]
@onready var speedrun_timers = $CanvasLayer/SpeedrunTimers

func _ready():
	_vines_bar.max_value = head.BASE_MAX_EXTENDED_LEN
	_sun_bar.max_value = head.BASE_MAX_EXTENDED_LEN
	_lightning_bar.max_value = head.MAX_LIGHTNING_BUFF
	_wind_bar.max_value = head.BASE_MAX_EXTENDED_LEN
	_vines_bar.value = 0.0
	_sun_bar.value = 0.0
	_lightning_bar.value = 0.0
	_wind_bar.value = head.BASE_MAX_EXTENDED_LEN
	instance = self
	initialized.emit()
	is_initialized = true

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
	switch_bars_tween.tween_property(_sun_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func switch_to_wind_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func switch_to_sun_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_vines_bar, "position:y", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	switch_bars_tween.tween_property(_sun_bar, "position:y", 1.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
func switch_to_no_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -60.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

func set_vine_windiness(windiness : float):
	_vines_bar.material.set_shader_parameter("windiness", windiness)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if shake_strength:
		shake_strength = move_toward(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	# Set hud progress bar values
	var goal_alpha := 1.0
	if head.can_extend:
		if head.extra_len_display == head.BASE_MAX_EXTENDED_LEN:
			_sun_bar.value = head.BASE_MAX_EXTENDED_LEN
		goal_alpha = 1.0
	else: 
		if Input.is_action_just_pressed("extend"):
			shake()
		goal_alpha = 0.2
	const STR = 10.0
	var diff 
	diff = abs(head.vine_len_display - _vines_bar.value)
	_vines_bar.value = move_toward(_vines_bar.value, head.vine_len_display, max(diff * STR * delta, 1))
	diff = abs(head.extra_len_display - _sun_bar.value)
	_sun_bar.value =move_toward(_sun_bar.value, head.extra_len_display, max(diff * STR * delta, 1))
	diff = abs(head.lightning_buff_amount - _lightning_bar.value)
	_lightning_bar.value =move_toward(_lightning_bar.value, head.lightning_buff_amount, max(diff * STR * 2.0 * delta, 1))
	diff = abs(head.wind_extra_len_display - _wind_bar.value)
	_wind_bar.value =move_toward(_wind_bar.value, head.wind_extra_len_display, max(diff * STR * delta, 1))
	diff = abs(goal_alpha - _vines_bar.modulate.a)
	_vines_bar.modulate.a = move_toward(_vines_bar.modulate.a, goal_alpha, diff * STR * delta)
	# Shake bar if necessary
	if shake_strength:
		$CanvasLayer.offset = get_random_offset()
	speedrun_timers.visible = Values.speedrun_mode

func shake(multiplier := 1.0):
	shake_strength = RANDOM_SHAKE_STRENGTH * multiplier

func get_random_offset():
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)