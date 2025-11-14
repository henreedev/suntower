extends Node

var total_force := Vector2.ZERO
var force_count := 0

@onready var parent: RigidBody2D = get_parent()

func apply_central_force(force: Vector2):
	total_force += force
	force_count += 1

func _physics_process(_delta: float) -> void:
	if force_count != 0:
		var averaged_force = total_force / float(force_count)
		parent.apply_central_force(averaged_force)
	
	# Reset
	total_force = Vector2.ZERO
	force_count = 0
