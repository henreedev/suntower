extends Node2D

class_name SunRays

signal sun_hit

var num_rays = 450
var offset_height = -num_rays / 2 - 50
var leader = false
var vine_tween : Tween
var curr_rot : float
var check_stride = 2 # actually check collisions on every n rays (for performance)
@export var right = true # are these rays placed on the right side of the tower?
@onready var _player : Head = get_tree().get_first_node_in_group("flowerhead")
@onready var _tower : Tower = get_tree().get_first_node_in_group("tower")
@onready var _pot : Pot = get_tree().get_first_node_in_group("pot")
# Called when the node enters the scene tree for the first time.
func _ready():
	_make_rays(num_rays)
	get_tree().get_first_node_in_group("sunrays").leader = true

func _make_rays(count):
	for i in count:
		var ray = RayCast2D.new()
		ray.add_exception(_pot)
		ray.target_position = Vector2(0, 1000)
		add_child(ray)
		ray.position = Vector2(0, i)
		ray.add_to_group("rays")
		ray.collision_mask = 1 + 2 + 16 + 32
		 #Visualization line
		#if i % 5 == 0:
			#var line = Line2D.new()
			#ray.add_child(line)
			#line.add_point(Vector2(0, 0))
			#line.add_point(ray.target_position)
			#line.width = 1
			#line.z_index = 99
			#line.modulate.a = 0.1

func set_rotate(angle):
	get_tree().set_group("rays", "rotation", angle)
	curr_rot = angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var rot_adj = 0# (PI / 2 - abs(curr_rot)) * 50
	position = Vector2(position.x, _player.position.y + offset_height + rot_adj)

func _physics_process(delta):
	if leader and _check_player_hit():
		_player._on_sunrays_hit()

func _sunrays_pointing_into_tower(sunrays : SunRays):
	var lights_adj_rot = fmod(Tower.instance._lights.rotation, TAU)
	if lights_adj_rot < 0: lights_adj_rot += TAU
	var lights_right = lights_adj_rot < PI 
	var should_hit = sunrays.right and lights_right || not sunrays.right and not lights_right
	return should_hit

var i = 0

func _check_player_hit():
	if i == check_stride:
		i = 1
		if _tower.weather == Tower.Weather.STORMY and _tower.lightning_striking:
			for sunrays : SunRays in get_tree().get_nodes_in_group("sunrays"):
				if _sunrays_pointing_into_tower(sunrays): # only check rays pointing into tower
					for ray : RayCast2D in sunrays.get_children():
						ray.collision_mask = 1 + 2 + 16 + 32 # Include vine segs
						var hit = ray.get_collider()
						if not hit: continue
						if hit is Head or hit is Vine or hit.is_in_group("flowerhead"):
							return true
			return false
		elif _tower.weather == Tower.Weather.SUNNY:
			if not _player._state == Head.State.EXTENDING: 
				return false
			for sunrays : SunRays in get_tree().get_nodes_in_group("sunrays"):
				if _sunrays_pointing_into_tower(sunrays): # only check rays pointing into tower
					for ray : RayCast2D in sunrays.get_children():
						var hit = ray.get_collider()
						if hit is Head or hit is Vine or (hit.is_in_group("flowerhead") if hit else false):
							#if not _player._animating and hit is Vine:
								#if not vine_tween: vine_tween = create_tween().set_parallel()
								#vine_tween.tween_property(hit.sprite, "modulate", Color(1.0, 5.0, 1.0), 0.25)
								#vine_tween.chain().tween_property(hit.sprite, "modulate", Color(1.0, 1.0, 1.0), 0.25)
							return true
			return false
		elif _tower.weather == Tower.Weather.WINDY:
			if not _player._state == Head.State.EXTENDING: 
				return false
			for sunrays : SunRays in get_tree().get_nodes_in_group("sunrays"):
				if _sunrays_pointing_into_tower(sunrays): # only check rays pointing into tower
					for ray : RayCast2D in sunrays.get_children():
						ray.collision_mask = 1 + 16 + 32 # Exclude vine segs
						var hit = ray.get_collider()
						if hit is Head or (hit.is_in_group("flowerhead") if hit else false):
							return true
			return false
		else: return false
	else:
		i += 1
		return false
