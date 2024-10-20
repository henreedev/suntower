extends Node2D
class_name VictorySequence

const LEAD_IN_ZOOM := Vector2(6, 6)
const FINAL_ZOOM := Vector2(9, 9)
const FADE_DURATION := 0.5

var fade_tween : Tween

var on_final_splash := false
var final_splash_loops := 0
var loops_until_jump := 4

@onready var final_splash : AnimatedSprite2D = $FinalSplash
@onready var lead_in_anims : AnimatedSprite2D = $LeadInAnims
@onready var cam : Camera2D = $Camera2D
@onready var color_rect : ColorRect = $ColorRect
@onready var menu_button : TextureButton = $MenuButton

@onready var peek_anim_dur = lead_in_anims.sprite_frames.get_frame_count("peek") * 1.0 / lead_in_anims.sprite_frames.get_animation_speed("peek")
@onready var throw_anim_dur = lead_in_anims.sprite_frames.get_frame_count("throw") * 1.0 / lead_in_anims.sprite_frames.get_animation_speed("throw")


# Called when the node enters the scene tree for the first time.
func _ready():
	color_rect.modulate.a = 1.0
	menu_button.modulate.a = 0.0
	menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_sequence():
	# reset sequence values
	cam.zoom = LEAD_IN_ZOOM
	color_rect.modulate.a = 1.0
	menu_button.modulate.a = 0.0
	menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	lead_in_anims.visible = true
	lead_in_anims.stop()
	lead_in_anims.animation = "peek"
	
	final_splash.visible = false
	final_splash.stop()
	final_splash.animation = "default"
	on_final_splash = false
	final_splash_loops = 0
	
	# show first animation
	fade(false)
	lead_in_anims.play()
	await Timing.create_timer(self, peek_anim_dur - FADE_DURATION)
	fade(true)
	
	# wait
	await Timing.create_timer(self, 2.0)
	
	# show second animation
	fade(false)
	lead_in_anims.animation = "throw"
	lead_in_anims.play()
	await Timing.create_timer(self, throw_anim_dur - FADE_DURATION)
	fade(true)
	
	# wait
	await Timing.create_timer(self, 2.0)
	# show final splash. allow this class to begin affecting final splash animations
	lead_in_anims.visible = false
	final_splash.visible = true
	cam.zoom = FINAL_ZOOM
	on_final_splash = true
	final_splash_loops = 0
	final_splash.play()
	SceneManager.instance.switch_bgm("Victory")
	
	# wait
	await Timing.create_timer(self, 6.0)
	create_tween().tween_property(menu_button, "modulate:a", 0.5, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	


func fade(to_opaque : bool, dur := FADE_DURATION):
	if fade_tween: fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(color_rect, "modulate:a", 1.0 if to_opaque else 0.0, dur)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _on_menu_button_pressed():
	SceneManager.instance.victory_to_menu()


func _on_final_splash_animation_looped():
	match final_splash.animation:
		"default":
			if final_splash_loops == 5:
				final_splash_loops = 0 
				final_splash.animation = "growing"
				final_splash.play()
			else:
				final_splash_loops += 1
		"growing_done":
			if final_splash_loops == loops_until_jump:
				final_splash_loops = 0
				loops_until_jump = randi_range(3, 8)
				final_splash.animation = "jumping"
				final_splash.play()

func _on_final_splash_animation_finished():
	match final_splash.animation:
		"growing", "jumping":
			final_splash.animation = "growing_done"
			final_splash.play()
