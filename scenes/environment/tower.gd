extends TileMap

class_name Tower

enum Weather {SUNNY, STORMY, WINDY, PEACEFUL}

var weather : Weather = Weather.SUNNY
var in_storm = false
var in_wind = false

var _progress = 0.0
const MAX_PROG = 3.5
const MAX_PROG_HEIGHT = -2268.0 # 3 screens of height 216 for the 3.5 sections
const INITIAL_DAY_OFFSET = 0.12
var _day_cycle_dur = 0.5
var _half_day_cycle_dur = _day_cycle_dur / 2.0
var _day_cycle = 0.0
var _right_day_start_angle = deg_to_rad(115.0)
var _right_day_end_angle = deg_to_rad(35.0)
var _left_day_start_angle = -_right_day_end_angle
var _left_day_end_angle = -_right_day_start_angle
var _goal_rotation = _right_day_start_angle
var _right = true
var sunny_modulate := Color(.635, .463, .51, 1.0)
var storm_modulate := Color(0.0, 0.0, 0.0, 1.0)
var modulate_tween : Tween 
var lightning_striking = false

@onready var _bg : Background = $ParallaxBackground
@onready var _player : FlowerHead = get_tree().get_first_node_in_group("flowerhead")
@onready var _lights : Lights = $Lights
@onready var _sunrays : SunRays = $SunRays
# Called when the node enters the scene tree for the first time.
func _ready():
	create_tween().set_loops().tween_callback(do_lightning).set_delay(4.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_change_weather_on_progress()
	_act_on_weather_state()
	_lerp_lights_towards_goal(delta)
	_sunrays.set_rotate($Lights.rotation)
	pass

func start_stormy():
	if not weather == Weather.STORMY:
		_lights.set_energy_mult(0.0)
		weather = Weather.STORMY
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		_bg.enter_storm(modulate_tween, 3.0)
		modulate_tween.tween_property($CanvasModulate, "color", storm_modulate, 1.0).set_trans(Tween.TRANS_CUBIC)

func start_sunny():
	if not weather == Weather.SUNNY:
		weather = Weather.SUNNY
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		_bg.exit_storm(modulate_tween, 3.0)
		modulate_tween.tween_property($CanvasModulate, "color", sunny_modulate, 2.0).set_trans(Tween.TRANS_CUBIC)

func _change_weather_on_progress():
	_progress = _player.position.y / MAX_PROG_HEIGHT
	if in_wind:
		weather = Weather.WINDY
	elif in_storm:
		start_stormy()
	else: 
		start_sunny()
	
	# calc light rotation
	var mult = 0.5 if weather == Weather.STORMY else 1.0
	_day_cycle = fmod(_progress + INITIAL_DAY_OFFSET, _day_cycle_dur * mult)
	_half_day_cycle_dur = _day_cycle_dur / 2 * mult
	if 0.0 <= _day_cycle and _day_cycle < _half_day_cycle_dur: 
		if not _right:
			var tween := create_tween()
			tween.tween_property(self, "_goal_rotation", _right_day_start_angle, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			_right = true
		else:
			_goal_rotation = lerp(_right_day_start_angle, _right_day_end_angle, _day_cycle / _half_day_cycle_dur)
	else:
		if _right:
			create_tween().tween_property(self, "_goal_rotation", _left_day_start_angle, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			_right = false
		else:
			_goal_rotation = lerp(_left_day_start_angle, _left_day_end_angle, fmod(_day_cycle, _half_day_cycle_dur) / _half_day_cycle_dur)

func _act_on_weather_state():
	match weather:
		Weather.SUNNY:
			var triangle = (-abs(_day_cycle - _half_day_cycle_dur) / _half_day_cycle_dur + 1)
			_lights.set_energy_mult(triangle * 2.5)
		Weather.STORMY:
			pass
		Weather.WINDY:
			pass # Wind hitboxes in level activate
		Weather.PEACEFUL:
			pass # Full sun, but hard platforming

func do_lightning():
	const lightning_duration = 0.2
	lightning_striking = true
	_lights.set_energy_mult(30.0)
	await get_tree().create_timer(lightning_duration).timeout
	create_tween().tween_method(_lights.set_energy_mult, 8.0, 0.015, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	lightning_striking = false

func _lerp_lights_towards_goal(delta):
	const rotation_strength = 1.5
	$Lights.rotation = lerp_angle($Lights.rotation, _goal_rotation, rotation_strength * delta)




func _on_storm_area_body_entered(body):
	if body is FlowerHead:
		in_storm = true


func _on_storm_area_body_exited(body):
	if body is FlowerHead:
		in_storm = false
