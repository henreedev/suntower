extends RigidBody2D
class_name Vine

var _set_pos
var _set_rot
var _set_child
var detached_child : Vine

var index := 0
var parent_vine := self

const BASE_SPRITE_SCALE := Vector2(1.0, 0.5)

@onready var sunlight_vfx_light: Sprite2D = $SunlightVfxLight
@onready var sprite : Sprite2D = $Sprite2D
@onready var sprite_scale = BASE_SPRITE_SCALE
@onready var light : PointLight2D = $StormLight
@onready var last_pos : Vector2 = position
@onready var fake_light : Sprite2D = $FakeLight
@onready var pin_joint_2d: PinJoint2D = $PinJoint2D
@onready var head: Head = get_tree().get_first_node_in_group("flowerhead")
@onready var tower: Tower = get_tree().get_first_node_in_group("tower")
@onready var force_averager: Node = $ForceAverager
var this_scene : PackedScene = preload("res://scenes/character/Vine.tscn")
var _rotation_match_node
var frame = 0
const SUNLIGHT_VFX_TRIGGER_COOLDOWN = 0.6
var sunlight_vfx_trigger_cooldown_timer := 0.0

## How bright sunlight vfx currently are on this vine.
var sunlight_vfx_intensity := 0.0

## Maximum sunlight visual effect intensity, shown upon sunlight hit. 
const MAX_SUNLIGHT_VFX_INTENSITY := 6.0 

## How many pixels per second at which the sunlight vfx propagate along vine segments.
const BASE_SUNLIGHT_VFX_PROPAGATE_SPEED = 80.0

var is_in_wind_tunnel := false

func _process(delta):
	frame += 1
	sprite.scale = sprite_scale
	last_pos = global_position
	#$Label.text = str(sprite_scale)
	var adjacent_vines = get_adjacent_vines()
	#$Label.text = str(adjacent_vines[0].index) + " before, " + str(adjacent_vines[1].index) + " after"
	#$Label.text = str(sunlight_vfx_intensity).pad_decimals(1)
	$Label.text = ""
	# Update intensity value and display it
	decrease_sunlight_vfx_intensity(delta)
	update_sunlight_vfx()
	
	# Tick sunlight vfx timer down to 0.0
	sunlight_vfx_trigger_cooldown_timer = max(0.0, sunlight_vfx_trigger_cooldown_timer - delta) 
 
func get_avg_pos():
	var avg_pos
	avg_pos = global_position
	return avg_pos


func create(child : RigidBody2D):
	var vine : Vine = this_scene.instantiate()
	vine.set_child(child)
	return vine

func set_child (child : RigidBody2D):
	_set_child = child
	if child is Vine:
		index = child.index + 1
		child.parent_vine = self

## Only returns if it's a vine. If it's a pot, returns self
func get_child_seg_vine(iterations := 0) -> Vine:
	var child = get_child_seg(iterations)
	return child if child is Vine else self
	
func get_child_seg(iterations := 0):
	var child : Node 
	if detached_child: child = detached_child
	else: child = get_node(pin_joint_2d.node_b) if not _set_child else _set_child
	if iterations > 0:
		return child.get_child_seg(iterations - 1)
	else: return child

func set_is_in_wind_tunnel(to: bool):
	is_in_wind_tunnel = to

func set_physics_variables(state: Head.State):
	match state:
		Head.State.INACTIVE:
			gravity_scale = -0.03
			linear_damp = 1.0
			angular_damp = 20.0
		Head.State.EXTENDING:
			if is_in_wind_tunnel:
				gravity_scale = 0.0
			else:
				gravity_scale = 0.1
		Head.State.RETRACTING:
			if head._segs > 60 and tower.weather == Tower.Weather.STORMY:
				gravity_scale = 0.0 # Avoid issues with too many segments being heavy
			else:
				gravity_scale = 0.3

func make_self_exception():
	get_tree().call_group("vine", "add_collision_exception_with", self)

func set_rotation_match(node):
	_rotation_match_node = node

func _set_electricity(val):
	if val > 0:
		sprite.material.set_shader_parameter("electricity", val)
		fake_light.visible = true
		fake_light.material.set_shader_parameter("intensity", val * 3)
	else: 
		fake_light.visible = false
		sprite.material.set_shader_parameter("electricity", 0)

var position_offset_to_integrate: Vector2
func apply_position_offset(offset: Vector2) -> void:
	position_offset_to_integrate += offset

func clear_position_offset() -> void:
	position_offset_to_integrate = Vector2.ZERO

func _integrate_forces(state):
	# Flush position offsets
	state.transform = state.transform.translated(position_offset_to_integrate)
	clear_position_offset()
	if _set_pos:
		state.transform = Transform2D(state.transform.get_rotation(), _set_pos)
		last_pos = _set_pos
		_set_pos = null
	if _set_rot:
		state.transform = Transform2D(_set_rot, state.transform.get_origin())
		_set_rot = null
	if _set_child:
		$PinJoint2D.node_b = _set_child.get_path()
		_set_child = null
	if _rotation_match_node:
		state.transform = Transform2D(_rotation_match_node.rotation, state.transform.get_origin())

## Finds nearby vines that didn't display recently, and tells them to display too.
func trigger_sunlight_vfx_chain(propagate_speed := 100.0) -> void:
	if sunlight_vfx_trigger_cooldown_timer != 0.0: return
	
	display_sunlight_vfx()
	
	# Start cooldown
	sunlight_vfx_trigger_cooldown_timer = SUNLIGHT_VFX_TRIGGER_COOLDOWN 
	
	var adjacent_vines := get_adjacent_vines()
	
	for vine : Vine in adjacent_vines:
		if vine == self: continue
		
		# Trigger adjacent vine based on a distance delay
		var dist = vine.global_position.distance_to(self.global_position)
		#var delay = dist / propagate_speed # Adjust propagation speed here
		var delay = dist / BASE_SUNLIGHT_VFX_PROPAGATE_SPEED # Adjust propagation speed here
		#var decelerated_propagate_speed = max(propagate_speed - 5.0, BASE_SUNLIGHT_VFX_PROPAGATE_SPEED)
		var decelerated_propagate_speed = BASE_SUNLIGHT_VFX_PROPAGATE_SPEED
		create_tween().tween_callback(
			vine.trigger_sunlight_vfx_chain.bind(decelerated_propagate_speed)
		).set_delay(delay)
	

## Displays sunlight visual effects, for when sunlight hits this vine. 
func display_sunlight_vfx() -> void:
	sunlight_vfx_light.visible = true
	set_sunlight_vfx_intensity(MAX_SUNLIGHT_VFX_INTENSITY)

func decrease_sunlight_vfx_intensity(delta : float):
	var curr = sunlight_vfx_intensity
	var new = max(0.0, 
		(move_toward(sunlight_vfx_intensity, 0.0, 1 * delta) + 
		lerpf(sunlight_vfx_intensity, 0.0, 1 * delta)) / 2.0
	)
	set_sunlight_vfx_intensity(new)

func set_sunlight_vfx_intensity(val : float):
	sunlight_vfx_intensity = val

func update_sunlight_vfx():
	if sunlight_vfx_intensity > 0:
		const OFFSET := 1.0
		const MAX_SHADER_INTENSITY := 2.5

		if sunlight_vfx_intensity > MAX_SUNLIGHT_VFX_INTENSITY - OFFSET:
			var threshold := MAX_SUNLIGHT_VFX_INTENSITY - OFFSET
			var overshoot := sunlight_vfx_intensity - threshold
			var t = clamp(overshoot / OFFSET, 0.0, 1.0) # normalized 0–1
			var shader_intensity := lerpf(0.0, MAX_SHADER_INTENSITY, t)
			
			sunlight_vfx_light.material.set_shader_parameter("intensity", shader_intensity)

		var mod = lerpf(1.0, 10.0, pow(sunlight_vfx_intensity / MAX_SUNLIGHT_VFX_INTENSITY, 6))
		modulate = Color(mod, mod, mod)
	else:
		sunlight_vfx_light.visible = false
		

func get_adjacent_vines() -> Array[Vine]:
	var before_vine := get_child_seg_vine()
	var after_vine := parent_vine
	#for vine : Vine in get_tree().get_nodes_in_group("vine"):
		#var before_index := index - 1
		#var after_index := index + 1
		#match vine.index:
			#before_index:
				#before_vine = vine
			#after_index:
				#after_vine = vine
			
	return [
		before_vine if before_vine != null else self, 
		after_vine if after_vine != null else self
	]

func is_on_sunlight_vfx_cooldown() -> bool:
	return sunlight_vfx_trigger_cooldown_timer != 0.0
