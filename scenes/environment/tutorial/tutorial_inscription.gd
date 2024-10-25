extends AnimatedSprite2D
class_name TutorialInscription

### Any AnimatedSprite2D with this script should have an animation called "active" that loops, 
### and an animation called "inactive" that doesn't

var should_become_inactive = false

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("animation_looped", _on_animation_looped)

func activate():
	animation = "active"
	play()

func deactivate():
	should_become_inactive = true

func _on_animation_looped():
	if should_become_inactive:
		animation = "inactive"
		should_become_inactive = false
	
