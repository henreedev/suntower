extends RigidBody2D
class_name Vine

var _set_pos
var _set_rot
var _set_child
var detached_child : Vine

var index = 0;

@onready var sprite : Sprite2D = $Sprite2D
@onready var sprite_scale = sprite.scale
@onready var light : PointLight2D = $StormLight
@onready var last_pos : Vector2 = position
@onready var fake_light : Sprite2D = $FakeLight
var this_scene : PackedScene = preload("res://scenes/character/Vine.tscn")
var _rotation_match_node
var frame = 0

func _process(delta):
	frame += 1
	sprite.scale = sprite_scale
	last_pos = global_position

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

func set_grav(grav : float):
	gravity_scale = grav

func get_child_seg(iterations := 0):
	var child : Node 
	if detached_child: child = detached_child
	else: child = get_node($PinJoint2D.node_b) if not _set_child else _set_child
	if iterations > 0:
		return child.get_child_seg(iterations - 1)
	else: return child

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
	if _set_rot:
		state.transform = Transform2D(_set_rot, state.transform.get_origin())
		_set_rot = null
	if _set_child:
		$PinJoint2D.node_b = _set_child.get_path()
		_set_child = null
	if _rotation_match_node:
		state.transform = Transform2D(_rotation_match_node.rotation, state.transform.get_origin())
