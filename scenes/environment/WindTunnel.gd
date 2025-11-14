extends Area2D

class_name WindTunnel

## Physics bodies currently inside this tunnel. 
var bodies: Array[RigidBody2D]

@onready var head: Head = get_tree().get_first_node_in_group("flowerhead")
@onready var pot: Pot = get_tree().get_first_node_in_group("pot")

static var bodies_dict: Dictionary[RigidBody2D, Array]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	for body in bodies:
		var forward_dir := Vector2.from_angle(rotation)
		
		# Apply a force that centers the body along the horizontal axis of this wind tunnel.
		var pos_diff = global_position - body.global_position
		var vec_normal_to_center_line := pos_diff.slide(forward_dir)
		var dir_to_center_line := vec_normal_to_center_line.normalized()
		var dist_to_center_line := vec_normal_to_center_line.length()
		const BASE_CENTER_LINE_STRENGTH = 5
		
		var center_line_force := dir_to_center_line * BASE_CENTER_LINE_STRENGTH * dist_to_center_line
		
		# Push based on difference from goal velocity 
		var body_forward_speed := body.linear_velocity.dot(forward_dir)
		var forward_force_ratio = inverse_lerp(100, -100, body_forward_speed)
		forward_force_ratio = clampf(forward_force_ratio, 0.5, 1.5)
		const BASE_FORWARD_FORCE_STRENGTH = 250.0
		var forward_force = forward_dir * BASE_FORWARD_FORCE_STRENGTH * forward_force_ratio
		
		## Push vines less
		var vine_multiplier = 0.05 if body is Vine else 1.0
		
		var force_as_accel = (forward_force + center_line_force) * body.mass * vine_multiplier
		body.force_averager.apply_central_force(force_as_accel)

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("flowerhead") or body.is_in_group("pot") or body.is_in_group("vine")):
		return
	if not body is RigidBody2D:
		return
	var rigidbody: RigidBody2D = body
	print("Body entered: ", rigidbody.get_groups())
	bodies.append(rigidbody)
	if not bodies_dict.has(rigidbody):
		bodies_dict[rigidbody] = []
	bodies_dict[rigidbody].append(self)
	rigidbody.set_is_in_wind_tunnel(true)
	rigidbody.set_physics_variables(head._state)
	if rigidbody.is_in_group("flowerhead"):
		pot.set_physics_variables(head._state)


func _on_body_exited(body: Node2D) -> void:
	if not (body.is_in_group("flowerhead") or body.is_in_group("pot") or body.is_in_group("vine")):
		return
	if not body is RigidBody2D:
		return
	var rigidbody: RigidBody2D = body
	
	print("Body exited: ", rigidbody.get_groups())
	bodies.erase(rigidbody)
	assert(bodies_dict.has(rigidbody))
	bodies_dict[rigidbody].erase(self)
	if bodies_dict[rigidbody].is_empty():
		rigidbody.set_is_in_wind_tunnel(false)
	rigidbody.set_physics_variables(head._state)
