extends Node2D

class_name Game


# Emitted after _ready() is complete
signal initialized 
var is_initialized := false

# Singleton access to this class
static var instance : Game

# Shake variables
var hud_offset := Vector2(0,-50)
var shake_strength = 0.0
const SHAKE_DECAY_RATE = 200.0
const RANDOM_SHAKE_STRENGTH = 30.0

# Tween used to switch resource bars
var switch_bars_tween : Tween

# Resource bars
@onready var _vines_bar : TextureProgressBar = $CanvasLayer/VinesBar
@onready var _sun_bar : TextureProgressBar = $CanvasLayer/SunBar
@onready var _lightning_bar : TextureProgressBar = $CanvasLayer/LightningBar
@onready var _wind_bar : TextureProgressBar = $CanvasLayer/WindBar

# References to important nodes
@onready var head : Head = $Head
@onready var _cam : Camera2D = $Head/Camera2D
@onready var pause_menu = $PauseMenu

# Screen-wide rectangle for fade transition upon victory
@onready var color_rect : ColorRect = $CanvasLayer/ColorRect

# Speedrun timing variables
@onready var time_trackers : Array[TimeTracker] = [%SunTime, %StormTime, %WindTime, %PeacefulTime]
@onready var speedrun_timers = $CanvasLayer/SpeedrunTimers

# Initializes resource bars and singleton instance.
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

# Pause on input, avoiding re-pausing the moment the pause menu unpauses
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not pause_menu.just_unpaused:
		pause()

# Pauses the game.
func pause():
	if not get_tree().paused:
		get_tree().paused = true
		pause_menu.options_menu.refresh()
		pause_menu.show()
	SceneManager.instance.reduce_music_volume()

# Tweens the lightning bar to a visible position, moving the previous bar off-screen.
func switch_to_lightning_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

# Tweens the wind bar to a visible position, moving the previous bar off-screen.
func switch_to_wind_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

# Tweens the sun bar to a visible position, moving the previous bar off-screen.
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

# Tweens resource bars off-screen, leaving only the vine resource bar.
func switch_to_no_bar():
	if switch_bars_tween:
		switch_bars_tween.kill()
	switch_bars_tween = create_tween()
	switch_bars_tween.tween_interval(1.5)
	switch_bars_tween.set_parallel()
	switch_bars_tween.tween_property(_sun_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_lightning_bar, "position:y", -60.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	switch_bars_tween.tween_property(_wind_bar, "position:y", -60.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

# Sets the shader value for the vine bar to make it gray with a scrolling wind texture.
func set_vine_windiness(windiness : float):
	_vines_bar.material.set_shader_parameter("windiness", windiness)

# Updates all resource bars, shakes HUD elements, and shows/hides speedrun timers.
func _process(delta):
	_update_resource_bars(delta)
	_update_shake(delta)
	speedrun_timers.visible = Values.speedrun_mode

# Smooths the movement of resource bar values and handles visuals of able to extend or not.
func _update_resource_bars(delta):
	const STR = 10.0
	var goal_alpha := 1.0
	if head.can_extend:
		if head.extra_len_display == head.BASE_MAX_EXTENDED_LEN:
			# When sun buff is applied, immediately move to correct value
			_sun_bar.value = head.BASE_MAX_EXTENDED_LEN 
		# Show vines opaque if can extend
		goal_alpha = 1.0
	else: 
		if Input.is_action_just_pressed("extend"):
			# Shake UI when player tries to extend and it's not allowed
			shake()
		# Show vines transparent if cannot extend
		goal_alpha = 0.2
	
	# Smoothly move resource values (and transparency) towards where they should be
	var diff : float  # The difference between desired value and current value
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
	

# Shakes the HUD and reduces shake if shake strength is positive.
func _update_shake(delta):
	if shake_strength:
		$CanvasLayer.offset = get_random_offset()
		shake_strength = move_toward(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)

# Initiates a shake of a certain strength.
func shake(multiplier := 1.0):
	shake_strength = RANDOM_SHAKE_STRENGTH * multiplier

# Returns a random position based on current shake strength.
func get_random_offset():
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
