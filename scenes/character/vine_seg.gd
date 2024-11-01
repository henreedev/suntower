extends RigidBody2D
class_name Vine

var _set_pos
var _set_rot
var _set_child
var detached_child : Vine
@onready var sprite : Sprite2D = $Smoothing2D/Sprite2D
@onready var sprite_scale = sprite.scale
@onready var light : PointLight2D = $Smoothing2D/StormLight
@onready var smooth : Smoothing2D = $Smoothing2D
@onready var last_pos : Vector2 = position
@onready var fake_light : Sprite2D = $Smoothing2D/FakeLight
var this_scene : PackedScene = preload("res://scenes/characters/vine_seg.tscn")
var _rotation_match_node
var smoothing = false
var frame = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	smooth.set_enabled(false)
	smoothing = false
	await Timing.create_timer(self, 0.2)
	smooth.set_enabled(true)
	smooth.teleport()
	smoothing = true

func _process(delta):
	frame += 1
	sprite.scale = sprite_scale
	last_pos = smooth.global_position if smoothing else global_position

func get_avg_pos():
	var avg_pos
	avg_pos = ((last_pos + smooth.global_position) / 2.0) if smoothing else global_position
	return avg_pos


func create(child : RigidBody2D):
	var vine : Vine = this_scene.instantiate()
	vine.set_child(child)
	return vine

func set_child (child : RigidBody2D):
	_set_child = child

func set_grav(grav : float):
	gravity_scale = grav

func get_child_seg():
	if detached_child: return detached_child
	return get_node($PinJoint2D.node_b) if not _set_child else _set_child

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


func _integrate_forces(state):
	if _set_pos:
		state.transform = Transform2D(state.transform.get_rotation(), _set_pos)
		last_pos = _set_pos
		_set_pos = null
		$Smoothing2D.set_enabled(true)
		smoothing = true
		$Smoothing2D.teleport()
	if _set_rot:
		state.transform = Transform2D(_set_rot, state.transform.get_origin())
		_set_rot = null
		$Smoothing2D.set_enabled(true)
		smoothing = true
		$Smoothing2D.teleport()
	if _set_child:
		$PinJoint2D.node_b = _set_child.get_path()
		_set_child = null
	if _rotation_match_node:
		state.transform = Transform2D(_rotation_match_node.rotation, state.transform.get_origin())
