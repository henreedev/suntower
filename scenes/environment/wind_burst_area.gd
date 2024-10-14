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


func _disable_for_duration():
	if disable_duration > 0:
		collision_shape_2d.set_deferred("disabled", true)
		await Timing.create_timer(self, disable_duration)
		collision_shape_2d.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body is Player2:
		Tower.instance.do_wind_burst(burst_direction_vec, burst_strength, burst_overall_duration)



func _on_body_exited(body: Node2D) -> void:
	_disable_for_duration()
