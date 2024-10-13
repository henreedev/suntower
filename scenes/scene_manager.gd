extends Node2D

class_name SceneManager

#static var sound_volume_offset_menu = -12.0
#static var sound_volume_offset_sun = -10.0
#static var sound_volume_offset_storm = -10.0
static var skip_cutscene = false

var base_volume : float
var player_volume_offset := 0.0
var tween_volume_offset := 0.0
var volume_tween : Tween

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
var playback : AudioStreamPlaybackInteractive
var stream : AudioStreamInteractive
@onready var game : Main = $Main
@onready var start_menu = $Menu
var level_switch_tween : Tween
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D

static var instance : SceneManager

# Called when the node enters the scene tree for the first time.
func _ready():
	instance = self
	playback = audio_stream_player.get_stream_playback()
	stream = audio_stream_player.stream
	base_volume = audio_stream_player.volume_db
	remove_child(game)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	audio_stream_player.volume_db = base_volume + player_volume_offset + tween_volume_offset
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func menu_to_game():
	tween_transition([remove_child.bind(start_menu), add_child.bind(game), \
		switch_bgm.bind("Sun")])


func game_to_menu():
	tween_transition([remove_child.bind(game), add_child.bind(start_menu), \
	 switch_bgm.bind("Menu")])

func switch_bgm(name : String):
	playback.switch_to_clip_by_name(name)


func tween_transition(method_calls : Array[Callable]):
	if level_switch_tween:
		level_switch_tween.kill()
	level_switch_tween = create_tween()
	level_switch_tween.tween_property(color_rect, "modulate:a", 1.0, 0.75)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	level_switch_tween.parallel().tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.75)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for callable : Callable in method_calls:
		level_switch_tween.tween_callback(callable)
	level_switch_tween.tween_property(color_rect, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	level_switch_tween.parallel().tween_property(animated_sprite_2d, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

#func _on_transition_overlay_transitioned():
	## store volume
	#start_game()
#
#func start_game():
	#var child = $CurrentScene.get_child(0)
	#child.queue_free()
	#$CurrentScene.remove_child(child)
	##await get_tree().create_timer(0.2).timeout
	#if skip_cutscene:
		#var game = game_scene.instantiate()
		#game.get_node("FlowerHead").play_animation_on_start = false
		#$CurrentScene.add_child(game)
	#else:
		#var game = game_scene.instantiate()
		#game.get_node("FlowerHead").play_animation_on_start = true
		#$CurrentScene.add_child(game)
		#skip_cutscene = true
