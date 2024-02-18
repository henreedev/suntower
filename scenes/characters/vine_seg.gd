extends RigidBody2D
class_name Vine

var _set_pos
var _set_child

var this_scene : PackedScene = preload("res://scenes/characters/vine_seg.tscn")
var _rotation_match_node
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func create(child : RigidBody2D):
	var vine : Vine = this_scene.instantiate()
	vine.set_child(child)
	return vine

func set_child (child : RigidBody2D):
	_set_child = child
	
func get_child_seg():
	return get_node($PinJoint2D.node_b) if not _set_child else _set_child

func make_self_exception():
	get_tree().call_group("vine", "add_collision_exception_with", self)

func set_rotation_match(node):
	_rotation_match_node = node

func _integrate_forces(state):
	if _set_pos:
		state.transform = Transform2D(state.transform.get_rotation(), _set_pos)
		_set_pos = null
	if _set_child:
		$PinJoint2D.node_b = _set_child.get_path()
		_set_child = null
	if _rotation_match_node:
		state.transform = Transform2D(_rotation_match_node.rotation, state.transform.get_origin())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
