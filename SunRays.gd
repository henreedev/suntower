extends Node2D

signal sun_hit

@export var num_rays = 216
var offset_height = -num_rays / 2
var leader = false
@onready var _player = get_tree().get_first_node_in_group("flowerhead")
# Called when the node enters the scene tree for the first time.
func _ready():
	_make_rays(num_rays)
	get_tree().get_first_node_in_group("sunrays").leader = true

func _make_rays(count):
	for i in count:
		var ray = RayCast2D.new()
		ray.target_position = Vector2(0, 1000)
		add_child(ray)
		ray.position = Vector2(0, i)
		ray.add_to_group("rays")
		ray.collision_mask = 2
		var line = Line2D.new()
		ray.add_child(line)
		line.add_point(Vector2(0, 0))
		line.add_point(ray.target_position.rotated(-1.1))
		line.width = 1

func set_rotate(angle):
	print(angle)
	get_tree().set_group("rays", "rotation", angle)
	#get_tree().set_group("rays", "target_position", Vector2(0, 1000).rotated(angle))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = Vector2(position.x, _player.position.y + offset_height)

func _physics_process(delta):
	if leader and _check_player_hit():
		sun_hit.emit()
		print("emitted sun_hit")

func _check_player_hit():
	for ray : RayCast2D in get_tree().get_nodes_in_group("rays"):
		var hit = ray.get_collider()
		if hit:
			hit.modulate = Color(1.5, 1.5, 1.5)
		if hit is Vine or hit is FlowerHead:
			return true
	return false
