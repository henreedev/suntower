extends Control

# The rate of the title blur pulsing. Equal to a half-bar of menu music.
var rate = 0.652 * 2

@onready var title_blur = $Background/TitleBlur
@onready var options_menu : OptionsMenu = $OptionsMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	# Fade in from black
	create_tween().tween_property(self, "modulate", Color.WHITE, 2.0)\
		.from(Color.BLACK).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Begin animating title
	animate_title()

# Tweens the blur behind the title to create a breathing pulse effect. Loops every two bars of menu music.
func animate_title():
	const STR = 1.5
	var tween = create_tween().set_loops()
	tween.tween_property(title_blur, "modulate", Color.WHITE * STR, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_blur, "modulate", Color.WHITE, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(title_blur, "modulate", Color.GRAY, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_blur, "modulate", Color.WHITE, rate).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

# Transitions to game.
func _on_start_button_pressed():
	SceneManager.instance.menu_to_game()

# Toggles the options menu.
func _on_options_button_pressed():
	options_menu.toggle()

# Closes the game.
func _on_quit_button_pressed():
	SceneManager.instance.quit_game()
