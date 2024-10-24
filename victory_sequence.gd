extends Node2D
class_name VictorySequence

const LEAD_IN_ZOOM := Vector2(6, 6)
const FINAL_ZOOM := Vector2(9, 9)
const FADE_IN_DURATION := 1.5
const FADE_OUT_DURATION := 1.0
const LONG_FADE_DURATION := 3.0

var fade_tween : Tween

var on_final_splash := false
var final_splash_loops := 0
var loops_until_jump := 4

@onready var final_splash : AnimatedSprite2D = $FinalSplash
@onready var lead_in_anims : AnimatedSprite2D = $LeadInAnims
@onready var cam : Camera2D = $Camera2D
@onready var color_rect : ColorRect = $ColorRect
@onready var menu_button : TextureButton = $MenuButton

@onready var peek_anim_dur = _get_anim_dur(lead_in_anims.sprite_frames, "peek")
@onready var throw_anim_dur = _get_anim_dur(lead_in_anims.sprite_frames, "throw")


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
	
	# wait initial delay
	await Timing.create_timer(self, 2.75)
	
	# show first animation
	fade(false)
	lead_in_anims.play()
	await Timing.create_timer(self, peek_anim_dur - FADE_OUT_DURATION)
	fade(true)
	
	# wait
	await Timing.create_timer(self, 3.0)
	
	# show second animation
	fade(false)
	lead_in_anims.animation = "throw"
	lead_in_anims.play()
	await Timing.create_timer(self, throw_anim_dur - LONG_FADE_DURATION)
	fade(true, LONG_FADE_DURATION)
	
	# wait
	await Timing.create_timer(self, 4.0)
	# show final splash. allow this class to begin affecting final splash animations
	fade(false, LONG_FADE_DURATION)
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
	


func fade(to_opaque : bool, dur := -1):
	if dur == -1:
		# no custom duration
		dur = FADE_OUT_DURATION if to_opaque else FADE_IN_DURATION
	if fade_tween: fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(color_rect, "modulate:a", 1.0 if to_opaque else 0.0, dur)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _get_anim_dur(sprite_frames : SpriteFrames, anim_name : String):
	var anim_len := sprite_frames.get_frame_count(anim_name)
	var anim_speed := 1.0 / sprite_frames.get_animation_speed(anim_name)
	var total_dur := 0.0
	for i in range(anim_len):
		total_dur += anim_speed * sprite_frames.get_frame_duration(anim_name, i)
	return total_dur

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
		"grown":
			if final_splash_loops == loops_until_jump:
				final_splash_loops = 0
				loops_until_jump = randi_range(1, 6)
				final_splash.animation = "jumping"
				final_splash.play()
			else:
				final_splash_loops += 1

func _on_final_splash_animation_finished():
	match final_splash.animation:
		"growing", "jumping":
			final_splash.animation = "grown"
			final_splash.play()
