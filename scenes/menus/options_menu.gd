extends Control
class_name OptionsMenu



var active := false
var tween : Tween
const FADE_COLOR = Color(5, 5, 5, 0)

func _ready():
	visible = false
	modulate = FADE_COLOR

func toggle():
	if tween: tween.kill()
	tween = create_tween()
	if active:
		tween.tween_property(self, "modulate", Color(2, 2, 2, 0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "visible", false, 0.0)
	else:
		refresh()
		visible = true
		tween.tween_property(self, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active = not active

func refresh():
	# TODO load correct volume and speedrun settings
	
	# TODO put correct numbers into RichTextLabels
	pass


func _on_check_button_toggled(toggled_on):
	Values.toggle_speedrun_mode(toggled_on)
