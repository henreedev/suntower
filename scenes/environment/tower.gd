extends Node2D

class_name Tower

enum Weather {SUNNY, STORMY, WINDY, PEACEFUL}

var weather : Weather = Weather.SUNNY
var in_storm = false
var in_wind = false

static var instance : Tower

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
var _right_day_start_angle_storm = deg_to_rad(110.0)
var _right_day_end_angle_storm = deg_to_rad(70.0)
var _left_day_start_angle_storm = -_right_day_end_angle_storm
var _left_day_end_angle_storm = -_right_day_start_angle_storm
var _right_day_start_angle_wind = deg_to_rad(100.0)
var _right_day_end_angle_wind = deg_to_rad(140.0)
var _left_day_start_angle_wind = -_right_day_start_angle_wind 
var _left_day_end_angle_wind = -_right_day_end_angle_wind
var _goal_rotation = _right_day_start_angle
var _right = true
var sunny_modulate := Color(.89, .89, .89, 1.0)
var storm_modulate := Color(0.0, 0.0, 0.0, 1.0)
var windy_modulate := Color.WHITE
var modulate_tween : Tween 
var lightning_striking = false
var lock_lights = false

# Wind variables
const BASE_WIND_STRENGTH := 70.0 # px/s^2
const WIND_STRENGTH_HIGH_PASS = 0.5 # wind strength value under which wind strength becomes 0
const WIND_ANCHOR_FALLOFF_DIST = 125.0 # px. wind strength becomes 0 at this distance from anchor 
var bodies_in_wind : Array = [] # all physics bodies that will be affected by passive wind 
var wind_direction := Vector2i(1, 0)
var wind_strength := 1.0 # multiplier on base strength
var wind_burst_tween : Tween
# This height is the value relative to which wind strength will decrease. 
# It is set to the pot's position on wind burst.
var wind_strength_anchor_height := 0.0 
var swap_tween : Tween

@onready var wind_area: Area2D = $WindArea
@onready var _bg : Background = $ParallaxBackground
@onready var _player : FlowerHead = get_tree().get_first_node_in_group("flowerhead")
@onready var _pot : Player2 = get_tree().get_first_node_in_group("player2")
@onready var _lights : Lights = $Lights
@onready var _sunrays : SunRays = $SunRays
@onready var main : Main = get_tree().get_first_node_in_group("main")

# Called when the node enters the scene tree for the first time.
func _ready():
	instance = self
	create_tween().set_loops().tween_callback(do_lightning).set_delay(5.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_change_weather_on_progress()
	_act_on_weather_state()
	_lerp_lights_towards_goal(delta)
	_sunrays.set_rotate($Lights.rotation)

func start_sunny():
	if not weather == Weather.SUNNY:
		weather = Weather.SUNNY
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		modulate_tween.tween_method(_lights.set_energy_mult, 0.0, 1.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_bg.enter_sunny(modulate_tween, 3.0)
		modulate_tween.tween_property($CanvasModulate, "color", sunny_modulate, 2.0).set_trans(Tween.TRANS_CUBIC)
		main.switch_to_sun_bar()
		SceneManager.instance.switch_bgm("Sun")

func start_stormy():
	if not weather == Weather.STORMY:
		weather = Weather.STORMY
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		modulate_tween.tween_method(_lights.set_energy_mult, _lights.get_energy_mult(), 0.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_bg.enter_storm(modulate_tween, 3.0)
		modulate_tween.tween_property($CanvasModulate, "color", storm_modulate, 1.0).set_trans(Tween.TRANS_CUBIC)
		main.switch_to_lightning_bar()
		SceneManager.instance.switch_bgm("Storm")
		_player.disable_wind_particles()
		_lights.set_wind_mode(false)


func start_windy():
	if not weather == Weather.WINDY:
		var old_weather = weather 
		weather = Weather.WINDY
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		modulate_tween.tween_method(_lights.set_energy_mult, _lights.get_energy_mult(), 0.4, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		_bg.enter_windy(modulate_tween, 3.0)
		modulate_tween.tween_property($CanvasModulate, "color", windy_modulate, 2.0).set_trans(Tween.TRANS_CUBIC)
		main.switch_to_wind_bar()
		SceneManager.instance.switch_bgm("Wind")
		_player.enable_wind_particles()
		_lights.set_wind_mode(true)


func _change_weather_on_progress():
	_progress = _player.position.y / MAX_PROG_HEIGHT
	if in_wind:
		start_windy()
	elif in_storm:
		start_stormy()
	else: 
		start_sunny()
	if not lock_lights: 
		# calc light rotation
		if weather == Weather.SUNNY:
			_day_cycle = fmod(_progress + INITIAL_DAY_OFFSET, _day_cycle_dur)
			_half_day_cycle_dur = _day_cycle_dur / 2
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
		elif weather == Weather.STORMY:
			var mult = 0.5
			_day_cycle = fmod(_progress + INITIAL_DAY_OFFSET, _day_cycle_dur * mult)
			_half_day_cycle_dur = _day_cycle_dur / 2 * mult
			
			if 0.0 <= _day_cycle and _day_cycle < _half_day_cycle_dur: 
				if not _right:
					var tween := create_tween()
					tween.tween_property(self, "_goal_rotation", _right_day_start_angle_storm, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
					_right = true
				else:
					_goal_rotation = lerp(_right_day_start_angle_storm, _right_day_end_angle_storm, _day_cycle / _half_day_cycle_dur)
			else:
				if _right:
					create_tween().tween_property(self, "_goal_rotation", _left_day_start_angle_storm, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
					_right = false
				else:
					_goal_rotation = lerp(_left_day_start_angle_storm, _left_day_end_angle_storm, fmod(_day_cycle, _half_day_cycle_dur) / _half_day_cycle_dur)
		elif weather == Weather.WINDY:
			_update_wind_strength()
			
			const mult = 0.4
			
			_day_cycle = fmod(_progress + INITIAL_DAY_OFFSET, _day_cycle_dur * mult)
			_half_day_cycle_dur = _day_cycle_dur / 2 * mult
			if 0.0 <= _day_cycle and _day_cycle < _half_day_cycle_dur: 
				if not _right:
					_swap_lights_instantly(_right)
				else:
					_goal_rotation = lerp(_right_day_start_angle_wind, _right_day_end_angle_wind, _day_cycle / _half_day_cycle_dur)
			else:
				if _right:
					_swap_lights_instantly(_right)
				else:
					_goal_rotation = lerp(_left_day_start_angle_wind, _left_day_end_angle_wind, fmod(_day_cycle, _half_day_cycle_dur) / _half_day_cycle_dur)
			

func _swap_lights_instantly(right_side):
	_right = not right_side
	lock_lights = true
	print("swapping")
	if swap_tween: swap_tween.kill()
	swap_tween = create_tween()
	
	swap_tween.tween_method(_lights.set_energy_mult, _lights.get_energy_mult(), 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	swap_tween.tween_property(self, "_goal_rotation", _left_day_start_angle_wind if right_side else _right_day_start_angle_wind, 0.0)
	swap_tween.tween_property(self, "lock_lights", false, 0.0)
	swap_tween.tween_callback(_set_lights_rotation_to_goal)
	swap_tween.tween_method(_lights.set_energy_mult, 0.0, 0.5, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_lights_rotation_to_goal():
	_lights.rotation = _goal_rotation

func _update_wind_strength():
	var str = clampf(wind_strength, 1.0, 10.0) # strength of the color of wind particles
	_player.update_wind_particles(wind_direction, wind_strength * BASE_WIND_STRENGTH, Color(str, str, str, 1.0))
	var normalized_dist = get_pot_dist_from_anchor() / WIND_ANCHOR_FALLOFF_DIST
	var new_str := lerpf(1.0, 0.0, normalized_dist)
	new_str = clampf(new_str, 0, 1)
	if new_str < WIND_STRENGTH_HIGH_PASS:
		new_str = 0.0
	wind_strength = clampf(new_str, 0, 1)

func _act_on_weather_state():
	match weather:
		Weather.SUNNY:
			var triangle = (-abs(_day_cycle - _half_day_cycle_dur) / _half_day_cycle_dur + 1)
			_lights.set_energy_mult(triangle * 2.5)
		Weather.STORMY:
			pass
		Weather.WINDY:
			pass
		Weather.PEACEFUL:
			pass # Full sun, but hard platforming


static var time = 0.0
func _physics_process(delta: float) -> void:
	if in_wind and weather == Weather.WINDY: 
		_apply_passive_wind()
		if time > 1.0:
			time = 0.0
			print("wind strength: " , wind_strength)
			print("wind dir: " , wind_direction)
			print()
		time += delta
		

func _apply_passive_wind():
	var wind_force = wind_direction * wind_strength * BASE_WIND_STRENGTH
	for body : RigidBody2D in bodies_in_wind:
		if body is FlowerHead:
			const MOD = 0.2;
			body.apply_central_force(wind_force * MOD)
		elif body is Player2:
			const MOD = 1.0;
			body.apply_central_force(wind_force * MOD)
		elif body is Vine: # must be a Vine
			const MOD = 0.2;
			body.apply_central_force(wind_force * MOD)

func do_wind_burst(dir : Vector2i, strength := 2.0, duration := 1.5):
	wind_direction = dir
	reset_wind_anchor()
	
	const CLOUD_SPEED = 1.0
	_bg.set_speed_mult(CLOUD_SPEED * dir.x, true, CLOUD_SPEED * strength * dir.x)
	
	if wind_burst_tween: 
		wind_burst_tween.kill()
	wind_burst_tween = create_tween() 
	
	wind_burst_tween.tween_property(self, "wind_strength", strength, duration * 0.33).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wind_burst_tween.tween_property(self, "wind_strength", 1.0, duration * 0.67).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func get_pot_dist_from_anchor():
	return abs(wind_strength_anchor_height - _pot.position.y)

func reset_wind_anchor(reset_to_head := false):
	if reset_to_head:
		wind_strength_anchor_height = _player.position.y
	else:
		wind_strength_anchor_height = _pot.position.y
	

func do_lightning():
	if weather == Weather.STORMY:
		lock_lights = true
		const cloud_brighten = 0.4
		const windup_duration = 1.0
		create_tween().tween_method(_lights.set_energy_mult, 0.04, 1.0, windup_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
		create_tween().tween_method(_bg.set_cloud_brightness, _bg.brightness, _bg.brightness + cloud_brighten, windup_duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)
		await Timing.create_timer(self, windup_duration + 0.05)
		
		const lightning_duration = 0.3
		_lights.set_energy_mult(20.0)
		_bg.set_cloud_brightness(_bg.brightness + cloud_brighten)
		lightning_striking = true
		await Timing.create_timer(self, lightning_duration)
		lightning_striking = false
		
		const winddown_duration = 0.5
		create_tween().tween_method(_lights.set_energy_mult, 1.0, 0.04, winddown_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		create_tween().tween_method(_bg.set_cloud_brightness, _bg.brightness + cloud_brighten, _bg.brightness, winddown_duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await Timing.create_timer(self, winddown_duration)
		lock_lights = false

func _lerp_lights_towards_goal(delta):
	var rotation_strength = 1.5 
	if weather == Weather.STORMY: rotation_strength = 5.0
	if weather == Weather.WINDY: rotation_strength = 2.0
	$Lights.rotation = lerp_angle($Lights.rotation, _goal_rotation, rotation_strength * delta)

func _on_storm_area_body_entered(body):
	if body is FlowerHead:
		in_storm = true

func _on_storm_area_body_exited(body):
	if body is FlowerHead:
		in_storm = false


func _on_wind_area_body_entered(body):
	if body is FlowerHead:
		in_wind = true
	bodies_in_wind.append(body)

func _on_wind_area_body_exited(body):
	if body is FlowerHead:
		in_wind = false
	bodies_in_wind.erase(body)
