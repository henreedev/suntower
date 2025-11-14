extends TileMapLayer

class_name TowerForeground

var tween: Tween

func hide_foreground():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.5,0.5,0.5,0.1), 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#tween.tween_callback(hide)

func show_foreground():
	if tween:
		tween.kill()
	tween = create_tween()
	#show()
	tween.tween_property(self, "modulate", Color.WHITE, 2.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
