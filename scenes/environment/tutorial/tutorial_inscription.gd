extends AnimatedSprite2D
class_name TutorialInscription

### Any AnimatedSprite2D with this script should have an animation called "active" that loops, 
### and an animation called "inactive" that doesn't

var should_become_inactive = false
const FADED_ALPHA = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("frame_changed", _on_frame_changed)
	self_modulate.a = FADED_ALPHA

func activate():
	animation = "active"
	play()
	create_tween().tween_property(self, "self_modulate:a", 1.0, 1.0)

func deactivate():
	should_become_inactive = true
	create_tween().tween_property(self, "self_modulate:a", FADED_ALPHA, 1.0)

func _on_frame_changed():
	if should_become_inactive:
		animation = "inactive"
		should_become_inactive = false
	
