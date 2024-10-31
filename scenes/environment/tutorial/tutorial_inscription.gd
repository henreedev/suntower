extends AnimatedSprite2D
class_name TutorialInscription

### Any AnimatedSprite2D with this script should have an animation called "active" that loops, 
### and an animation called "inactive" that doesn't

var should_become_inactive = false
const FADED_ALPHA = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("frame_changed", _on_frame_changed)
	self_modulate.a = FADED_ALPHA

func activate():
	var tween = create_tween().set_parallel()
	tween.tween_callback(start_active_anim).set_delay(0.75)
	tween.tween_property(self, "self_modulate:a", 1.0, 1.0).set_delay(0.75)

func start_active_anim():
	animation = "active"
	play()

func deactivate():
	should_become_inactive = true
	create_tween().tween_property(self, "self_modulate:a", FADED_ALPHA, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_frame_changed():
	if should_become_inactive:
		animation = "inactive"
		should_become_inactive = false
	
