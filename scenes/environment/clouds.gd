extends ScrollingSprite2D
class_name Clouds

@onready var parallax : ParallaxLayer = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	parallax.motion_mirroring = Vector2(384, 432) * scale
