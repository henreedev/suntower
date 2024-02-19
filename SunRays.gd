extends Node2D

signal sun_hit

var num_rays = 500
var offset_height = -num_rays / 2 - 50
var leader = false
@onready var _player : FlowerHead = get_tree().get_first_node_in_group("flowerhead")
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
		# Visualization line
		#var line = Line2D.new()
		#ray.add_child(line)
		#line.add_point(Vector2(0, 0))
		#line.add_point(ray.target_position)
		#line.width = 1

func set_rotate(angle):
	get_tree().set_group("rays", "rotation", angle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = Vector2(position.x, _player.position.y + offset_height)

func _physics_process(delta):
	if leader and _check_player_hit() and get_tree().get_first_node_in_group("lights").energy_mult != 0.0:
		_player._on_sunrays_hit()

func _check_player_hit():
	for ray : RayCast2D in get_tree().get_nodes_in_group("rays"):
		var hit = ray.get_collider()
		if hit is FlowerHead or hit is Vine or hit.is_in_group("flowerhead") if hit else false:
			var tween : Tween = create_tween()
			tween.tween_property(hit.get_node("Sprite2D"), "modulate", Color(1.0, 5.0, 1.0), 0.25)
			tween.tween_property(hit.get_node("Sprite2D"), "modulate", Color(1.0, 1.0, 1.0), 0.25)
			return true
	return false
