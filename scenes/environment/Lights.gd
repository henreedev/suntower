extends Node2D
class_name Lights

var energy_mult = 1.0
@onready var light_1_energy = $DirectionalLight2D.energy
@onready var light_2_energy = $DirectionalLight2D2.energy
@onready var light_3_energy = $DirectionalLight2D3.energy
@onready var light_1 : DirectionalLight2D = $DirectionalLight2D
@onready var light_2 : DirectionalLight2D = $DirectionalLight2D2
@onready var light_3 : DirectionalLight2D = $DirectionalLight2D3

@onready var base_light_1_rot := light_1.rotation
@onready var base_light_2_rot := light_3.rotation
@onready var base_light_3_rot := light_2.rotation
@onready var base_light_1_color := light_1.color
@onready var base_light_2_color := light_2.color
@onready var base_light_3_color := light_3.color
@onready var base_light_1_energy := light_1.energy
@onready var base_light_2_energy := light_2.energy
@onready var base_light_3_energy := light_3.energy

const WIND_ENERGY = 1.0

var wind_tween : Tween
var wind_tween_2 : Tween
var wind_tween_3 : Tween


static var count := 0
func set_energy_mult(val):
	energy_mult = val
	print("setting ", count)
	count += 1

func set_wind_mode(on : bool):
	if on:
		# darken lights, add shakiness to lights 2 and 3, add smooth filter to light 1
		if wind_tween: wind_tween.kill()
		if wind_tween_2: wind_tween.kill()
		if wind_tween_3: wind_tween.kill()
		wind_tween = create_tween()
		wind_tween.set_parallel()
		const DUR = 1.6
		light_1.shadow_filter = Light2D.ShadowFilter.SHADOW_FILTER_PCF13
		wind_tween.tween_property(light_1, "rotation", base_light_1_rot, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_1, "color", Color.WHITE, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_2, "color", Color(.67, .97, 1), DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_3, "color", Color(.67, .97, 1) * 0.7, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(self, "light_1_energy", WIND_ENERGY, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(self, "light_2_energy", base_light_2_energy, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(self, "light_3_energy", base_light_3_energy, DUR).set_trans(Tween.TRANS_CUBIC)
		
		const WIGGLE_DUR_1 = 0.278 * 2
		const WIGGLE_DUR_2 = 0.139 * 2
		wind_tween_2 = create_tween().set_loops()
		wind_tween_3 = create_tween().set_loops()
		wind_tween_2.tween_property(light_2, "rotation", deg_to_rad(1.0), WIGGLE_DUR_1).set_trans(Tween.TRANS_CUBIC)
		wind_tween_2.tween_property(light_2, "rotation", deg_to_rad(-1), WIGGLE_DUR_1).set_trans(Tween.TRANS_CUBIC)
		wind_tween_3.tween_property(light_3, "rotation", deg_to_rad(-0.8), WIGGLE_DUR_2).set_trans(Tween.TRANS_CUBIC)
		wind_tween_3.tween_property(light_3, "rotation", deg_to_rad(0.8), WIGGLE_DUR_2).set_trans(Tween.TRANS_CUBIC)
	else:
		# reset to default
		if wind_tween: wind_tween.kill()
		if wind_tween_2: wind_tween_2.kill()
		if wind_tween_3: wind_tween_3.kill()
		wind_tween = create_tween()
		wind_tween.set_parallel()
		const DUR = 1.6
		wind_tween.tween_property(light_1, "shadow_filter", Light2D.ShadowFilter.SHADOW_FILTER_NONE, DUR)
		wind_tween.tween_property(light_1, "rotation", base_light_1_rot, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_2, "rotation", base_light_2_rot, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_3, "rotation", base_light_3_rot, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_1, "color", base_light_1_color, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_2, "color", base_light_2_color, DUR).set_trans(Tween.TRANS_CUBIC)
		wind_tween.tween_property(light_3, "color", base_light_3_color, DUR).set_trans(Tween.TRANS_CUBIC)
		if Tower.instance.weather != Tower.Weather.STORMY:
			wind_tween.tween_property(self, "light_1_energy", base_light_1_energy, DUR).set_trans(Tween.TRANS_CUBIC)
			wind_tween.tween_property(self, "light_2_energy", base_light_2_energy, DUR).set_trans(Tween.TRANS_CUBIC)
			wind_tween.tween_property(self, "light_3_energy", base_light_3_energy, DUR).set_trans(Tween.TRANS_CUBIC)

func get_energy_mult():
	return energy_mult
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$DirectionalLight2D.energy = light_1_energy * energy_mult
	$DirectionalLight2D2.energy = light_2_energy * energy_mult
	$DirectionalLight2D3.energy = light_3_energy * energy_mult
