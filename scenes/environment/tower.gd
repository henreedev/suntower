extends Node2D

class_name Tower

enum Weather {SUNNY, STORMY, WINDY, PEACEFUL, VICTORY}

var weather : Weather = Weather.SUNNY
var in_storm = false
var in_wind = false
var in_peaceful = false

static var instance : Tower

var _progress = 0.0
var _prog_height_offset = 0.0
var progress_update_timer = 0.0



const MAX_PROG = 3.5
const MAX_PROG_HEIGHT = -2268.0 # 3 screens of height 216 for the 3.5 sections
const INITIAL_DAY_OFFSET = 0.12
const STORM_DAY_OFFSET = 0.12
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
var peaceful_modulate := Color(1.05, 1.05, 1.05, 1.0)
var modulate_tween : Tween 

# Storm variables
var lightning_striking = false
var lock_lights = false
var lightning_strike_tween : Tween
const STORM_MUSIC_8_BARS_DUR := 2.790696 * 2
const STORM_MUSIC_BEAT_DUR := .348837

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

@onready var tutorial_chunk : Tutorial = $LevelChunks/Sun/TutorialChunk
@onready var wind_area: Area2D = %WindArea
@onready var _bg : Background = $ParallaxBackground
@onready var _player : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var _pot : Pot = get_tree().get_first_node_in_group("pot")
@onready var _lights : Lights = $Lights

@onready var _sunrays : SunRays = $SunRays
@onready var main : Main = get_tree().get_first_node_in_group("main")
@onready var cam_max_marker : Marker2D = %CamMaxMarker
@onready var sun_reset_points : Array[SunResetPoint] = _get_reset_points()
@onready var start_height = int(%StartHeightMarker.global_position.y)
@onready var disable_occluders_marker = %DisableOccludersMarker
@onready var lightning_striker = %LightningStriker
@onready var stop_delay_timer : Timer = %StopDelayTimer
@onready var show_clouds_marker = %ShowCloudsMarker
var time_trackers : Array[TimeTracker] 

# Called when the node enters the scene tree for the first time.
func _ready():
	instance = self
	await main.initialized
	time_trackers = main.time_trackers
	_begin_tracking(Weather.SUNNY)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_update_progress_offset(delta)
	_change_weather_on_progress()
	_act_on_weather_state()
	_lerp_lights_towards_goal(delta)
	_sunrays.set_rotate($Lights.rotation)

func _update_progress_offset(delta):
	if progress_update_timer <= 0.0:
		progress_update_timer = 0.5
		const MAX = 999999.0
		var min_offset_height = MAX
		for reset_point : SunResetPoint in sun_reset_points:
			var y = reset_point.global_position.y
			if y < min_offset_height and \
			_player.global_position.y < y:
				min_offset_height = y
		if min_offset_height == MAX:
			_prog_height_offset = 0.0
		else:
			_prog_height_offset = min_offset_height
	else:
		progress_update_timer -= delta
	

func _get_reset_points(node : Node = self):
	var points : Array[SunResetPoint] = []
	for child in node.get_children():
		if child is SunResetPoint:
			points.append(child)
		else: points.append_array(_get_reset_points(child))
	return points

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
		Values.reach_section(weather)
		_begin_tracking(weather)
		time_trackers[weather]
		
		stop_lightning()

func _begin_tracking(next_weather : Weather):
	if not Values.cur_section > next_weather and int(next_weather) < len(time_trackers):
		time_trackers[next_weather].activate()
	if int(weather) > 0:
		time_trackers[next_weather - 1].lock_in_time()

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
		lightning_striker.process_mode = Node.PROCESS_MODE_INHERIT
		stop_delay_timer.stop()
		if not lightning_strike_tween:
			# TODO await duration of storm intro 
			lightning_strike_tween = create_tween().set_loops().bind_node(lightning_striker)
			lightning_strike_tween.tween_callback(do_lightning).set_delay(STORM_MUSIC_8_BARS_DUR)
		SceneManager.instance.switch_bgm("Storm")
		_player.disable_wind_particles()
		_lights.set_wind_mode(false)
		Values.reach_section(weather)
		_begin_tracking(weather)


func start_windy():
	if not weather == Weather.WINDY:       
		var old_weather = weather 
		weather = Weather.WINDY
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		_player.show_active_wind_particles()
		_bg.enter_windy(modulate_tween, 3.0)
		stop_lightning()
		modulate_tween.tween_property($CanvasModulate, "color", windy_modulate, 2.0).set_trans(Tween.TRANS_CUBIC)
		main.switch_to_wind_bar()
		SceneManager.instance.switch_bgm("Wind")
		_player.enable_wind_particles()
		_player.enable_occluders()
		_lights.set_wind_mode(true)
		Values.reach_section(weather)
		_begin_tracking(weather)

func start_peaceful():
	if not weather == Weather.PEACEFUL:
		weather = Weather.PEACEFUL
		if modulate_tween:
			modulate_tween.kill()
		modulate_tween = create_tween().set_parallel()
		_player.disable_wind_particles()
		_bg.enter_peaceful(modulate_tween, 3.0)
		modulate_tween.tween_property($CanvasModulate, "color", peaceful_modulate, 2.0).set_trans(Tween.TRANS_CUBIC)
		main.switch_to_no_bar()
		SceneManager.instance.switch_bgm("Peaceful")
		_player.disable_wind_particles()
		_lights.set_wind_mode(false)
		Values.reach_section(weather)
		_begin_tracking(weather)

func stop_lightning():
	stop_delay_timer.start(STORM_MUSIC_BEAT_DUR)

func win():
	if not Values.won:
		# animate the flower going up into the hole
		_player.set_deferred("freeze", true)
		_player._animating = true
		var flower_head_tween = create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		flower_head_tween.tween_property(_player, "rotation", 0.0, 1.0)
		flower_head_tween.tween_property(_player, "global_position:y", _player.global_position.y - _player.EXTEND_SPEED * 2.0, 2.5)
		flower_head_tween.tween_property(_player, "global_position:x", 0.0, 1.0)
		
		# indicate victory to Values 
		Values.update_height(_player.get_height())
		Values.win()
		_begin_tracking(Weather.VICTORY) # Locks in Peaceful timer
		
		# fade out and switch to victory sequence
		var win_tween := create_tween().set_parallel()
		win_tween.tween_property(_player.camera_2d, "zoom", Vector2(6, 6), 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		win_tween.tween_property(main.color_rect, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT) 
		win_tween.tween_callback(SceneManager.instance.game_to_victory).set_delay(2.5)


func _get_progress_height():
	return _player.position.y - _prog_height_offset

func _get_progress():
	return _get_progress_height() / MAX_PROG_HEIGHT

func _change_weather_on_progress():
	_progress = _get_progress()
	if in_peaceful: 
		start_peaceful()
	elif in_wind:
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
			_day_cycle = fmod(_progress + INITIAL_DAY_OFFSET + STORM_DAY_OFFSET, _day_cycle_dur * mult)
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
		elif weather == Weather.PEACEFUL:
			_goal_rotation = 0.0

func _swap_lights_instantly(right_side):
	_right = not right_side
	lock_lights = true
	if swap_tween: swap_tween.kill()
	swap_tween = create_tween()
	
	swap_tween.tween_method(_lights.set_energy_mult, _lights.get_energy_mult(), 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	swap_tween.tween_property(self, "_goal_rotation", _left_day_start_angle_wind if right_side else _right_day_start_angle_wind, 0.0)
	swap_tween.tween_property(self, "lock_lights", false, 0.0)
	swap_tween.tween_callback(_set_lights_rotation_to_goal)
	swap_tween.tween_method(_lights.set_energy_mult, 0.0, _lights.WIND_ENERGY, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

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
			var triangle = (-abs(_day_cycle - _half_day_cycle_dur) / _half_day_cycle_dur) + 1
			_lights.set_energy_mult(triangle * 2.5)
			if _player.global_position.y < show_clouds_marker.global_position.y:
				_bg.big_clouds.visible = true
			else:
				_bg.big_clouds.visible = false
		Weather.STORMY:
			pass
		Weather.WINDY:
			pass
		Weather.PEACEFUL:
			if _player.global_position.y < disable_occluders_marker.global_position.y:
				_player.disable_occluders()
			else:
				_player.enable_occluders()


static var time = 0.0
func _physics_process(delta: float) -> void:
	if in_wind and weather == Weather.WINDY: 
		_apply_passive_wind()
		if time > 1.0:
			time = 0.0
		time += delta
		

func _apply_passive_wind():
	var wind_force = wind_direction * wind_strength * BASE_WIND_STRENGTH
	for body : RigidBody2D in bodies_in_wind:
		if body is Head:
			const MOD = 0.2;
			body.apply_central_force(wind_force * MOD)
		elif body is Pot:
			const MOD = 1.0;
			body.apply_central_force(wind_force * MOD)
		elif body is Vine: # must be a Vine
			const MOD = 0.2;
			body.apply_central_force(wind_force * MOD)

func do_wind_burst(dir : Vector2i, strength := 2.0, duration := 1.5):
	wind_direction = dir
	reset_wind_anchor()
	
	const CLOUD_SPEED = 3.0
	_bg.set_speed_mult(CLOUD_SPEED * dir.x, true, CLOUD_SPEED * strength * dir.x)
	_bg.set_speed_mult(0.5 * CLOUD_SPEED * dir.x, false, 0.5 * CLOUD_SPEED * strength * dir.x)
	
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
		const cloud_brighten = 0.25
		const windup_duration = 1.1
		var rand_windup_dur = windup_duration * randf_range(0.8, 1.2)
		create_tween().tween_method(_lights.set_energy_mult, 0.04, 1.0, windup_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
		create_tween().tween_method(_bg.set_cloud_brightness, _bg.brightness, _bg.brightness + cloud_brighten, windup_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
		await Timing.create_timer(self, windup_duration + 0.05)
		
		const lightning_duration = 0.25
		var rand_lightning_dur = lightning_duration * randf_range(0.8, 1.2)
		_lights.set_energy_mult(20.0)
		_bg.set_cloud_brightness(_bg.brightness + cloud_brighten)
		lightning_striking = true
		await Timing.create_timer(self, lightning_duration)
		lightning_striking = false
		
		const winddown_duration = 1.0
		var rand_winddown_dur = winddown_duration * randf_range(0.8, 1.2)
		create_tween().tween_method(_lights.set_energy_mult, 1.0, 0.04, winddown_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		create_tween().tween_method(_bg.set_cloud_brightness, _bg.brightness + cloud_brighten, _bg.brightness, winddown_duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		await Timing.create_timer(self, winddown_duration)
		lock_lights = false

func _lerp_lights_towards_goal(delta):
	var rotation_strength = 1.5 
	if weather == Weather.STORMY: rotation_strength = 5.0
	if weather == Weather.WINDY: rotation_strength = 2.0
	if weather == Weather.PEACEFUL: rotation_strength = 10.0
	$Lights.rotation = lerp_angle($Lights.rotation, _goal_rotation, rotation_strength * delta)

func _on_storm_area_body_entered(body):
	if body is Head:
		in_storm = true

func _on_storm_area_body_exited(body):
	if body is Head:
		in_storm = false


func _on_wind_area_body_entered(body):
	if body is Head:
		in_wind = true
	bodies_in_wind.append(body)

func _on_wind_area_body_exited(body):
	if body is Head:
		in_wind = false
	bodies_in_wind.erase(body)


func _on_peaceful_area_body_entered(body):
	if body is Head:
		in_peaceful = true


func _on_peaceful_area_body_exited(body):
	if body is Head:
		in_peaceful = false


func _on_victory_area_body_entered(body):
	win()


func _on_stop_delay_timer_timeout():
	lightning_striker.process_mode = Node.PROCESS_MODE_DISABLED
