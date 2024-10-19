extends HSlider
class_name VolumeBar

@export_enum("Master", "Music", "SFX") var bus_name := "Master"
static var master_volume := 0.75
static var music_volume := 0.75
static var sfx_volume := 0.75
var bus_index = 0
var initialized = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	value_changed.connect(_on_value_changed)

func _process(_delta):
	if Values.initialized and not initialized:
		_update_all_bars()
		initialized = true


func _enter_tree() -> void:
	_update_all_bars()

func update_self():
	print("master = ", master_volume)
	match bus_name:
		"Master": 
			value = master_volume
		"Music": 
			value = music_volume
		"SFX": 
			value = sfx_volume

func _update_all_bars():
	update_self()
	for bar : VolumeBar in get_tree().get_nodes_in_group("volumebar"):
		bar.update_self()

func _on_value_changed(value : float):
	print("value changed to ", value)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(lerpf(0.0, 1.25, value)))
	match bus_name:
		"Master": 
			master_volume = value
		"Music": 
			music_volume = value
		"SFX": 
			sfx_volume = value


func _on_drag_ended(value_changed: bool) -> void:
	if value_changed:
		_on_value_changed(value)
		_update_all_bars()
