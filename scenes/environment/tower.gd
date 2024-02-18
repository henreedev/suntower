extends TileMap

enum Weather {SUNNY, STORMY, WINDY, PEACEFUL}

var _weather : Weather = Weather.SUNNY
var _progress = 0.0
const MAX_PROG = 3.5
const MAX_PROG_HEIGHT = -2250.0
const INITIAL_DAY_OFFSET = 0.057
var _day_cycle_dur = 0.33
var _half_day_cycle_dur = _day_cycle_dur / 2.0
var _day_cycle = 0.0
var _right_day_start_angle = deg_to_rad(115.0)
var _right_day_end_angle = deg_to_rad(35.0)
var _left_day_start_angle = -_right_day_end_angle
var _left_day_end_angle = -_right_day_start_angle
var _right = true
@onready var _player : FlowerHead = get_tree().get_first_node_in_group("flowerhead")
@onready var _lights : Lights = $Lights
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_change_weather_on_progress()
	_act_on_weather_state()
	$SunRays.set_rotate($Lights.rotation)
	pass

func _change_weather_on_progress():
	_progress = _player.position.y / MAX_PROG_HEIGHT
	if 0.0 <= _progress and _progress < 1.0:
		_weather = Weather.SUNNY
	elif 1.0 <= _progress and _progress < 2.0:
		_weather = Weather.STORMY
	elif 2.0 <= _progress and _progress < 3.0:
		_weather = Weather.WINDY
	elif 3.0 <= _progress:
		_weather = Weather.PEACEFUL
	
	# calc light rotation
	_day_cycle = fmod(_progress + INITIAL_DAY_OFFSET, _day_cycle_dur)
	if 0.0 <= _day_cycle and _day_cycle < _half_day_cycle_dur: 
		if not _right:
			var tween := create_tween()
			tween.tween_property($Lights, "rotation", _right_day_start_angle, 0.25)
			_right = true
		else:
			$Lights.rotation = lerp(_right_day_start_angle, _right_day_end_angle, _day_cycle / _half_day_cycle_dur)
	else:
		if _right:
			create_tween().tween_property($Lights, "rotation", _left_day_start_angle, 0.25)
			_right = false
		else:
			$Lights.rotation = lerp(_left_day_start_angle, _left_day_end_angle, fmod(_day_cycle, _half_day_cycle_dur) / _half_day_cycle_dur)

func _act_on_weather_state():
	match _weather:
		Weather.SUNNY:
			var triangle = (-abs(_day_cycle - _half_day_cycle_dur) / _half_day_cycle_dur + 1)
			_lights.set_energy_mult(triangle * 2.5)
		Weather.STORMY:
			pass # Lightning every 5-6 seconds, storm, rain sounds play
		Weather.WINDY:
			pass # Wind hitboxes in level activate
		Weather.PEACEFUL:
			pass # Full sun, but hard platforming
