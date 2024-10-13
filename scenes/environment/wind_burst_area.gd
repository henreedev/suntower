extends Area2D

@export_enum("Left", "Right") var burst_direction: int
@export_range(1.0, 5.0, 0.1) var burst_strength := 2.0
@export_range(1.0, 5.0, 0.1) var burst_overall_duration := 1.5
@export_range(0, 20, 1) var disable_duration := 5
var burst_direction_vec: Vector2i
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if burst_direction == 0: burst_direction = -1
	burst_direction_vec = Vector2i(burst_direction, 0)

func _on_body_entered(body: Node2D) -> void:
	if body is Player2:
		if body.velocity_diff > 0.1: # Pot is moving. Don't burst if pot wasn't (in case of reenabling)
			Tower.instance.do_wind_burst(burst_direction_vec, burst_strength, burst_overall_duration)
			

func _disable_for_duration():
	collision_shape_2d.disabled = true
	await Timing.create_timer(self, disable_duration)
	collision_shape_2d.disabled = false
