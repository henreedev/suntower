extends Node2D
class_name Lights

var energy_mult = 1.0
@onready var light_1_energy = $DirectionalLight2D.energy
@onready var light_2_energy = $DirectionalLight2D2.energy
@onready var light_3_energy = $DirectionalLight2D3.energy


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_energy_mult(val):
	energy_mult = val

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$DirectionalLight2D.energy = light_1_energy * energy_mult
	$DirectionalLight2D2.energy = light_2_energy * energy_mult
	$DirectionalLight2D3.energy = light_3_energy * energy_mult
