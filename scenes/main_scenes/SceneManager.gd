extends Node2D

class_name SceneManager

# Emitted after finishing initialization in _ready()
signal initialized
var is_initialized := false

# Game scene to initialize a new game with
const GAME_SCENE : PackedScene = preload("res://scenes/main_scenes/Game.tscn")

# Singleton instance
static var instance : SceneManager

# Volume variables
var base_volume : float
var player_volume_offset := 0.0
var tween_volume_offset := 0.0
var volume_tween : Tween

# Audio variables
var playback : AudioStreamPlaybackInteractive
var stream : AudioStreamInteractive

# Tween for switching levels using fade transitions and method callbacks.
var level_switch_tween : Tween

# Onready references to other nodes
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var game : Game = $Game
@onready var start_menu = $Menu
@onready var victory_sequence : VictorySequence = $VictorySequence
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D
@onready var victory_color_rect: ColorRect = $CanvasLayer/VictoryColorRect
@onready var sprite_2d: Sprite2D = $CanvasLayer/Sprite2D

# Used to only have one transition running at a time.
var can_transition := true

# Called when the node enters the scene tree for the first time.
# Loads save file and sets up audio and game values.
func _ready():
	# Don't auto-accept quit; we want to save user data first (quit_game())
	get_tree().set_auto_accept_quit(false)
	
	Values.load_user_data()
	
	instance = self
	
	_setup_audio()
	_setup_game()
	
	is_initialized = true
	initialized.emit()

# Sets audio variables.
func _setup_audio():
	playback = audio_stream_player.get_stream_playback()
	stream = audio_stream_player.stream
	base_volume = audio_stream_player.volume_db

# Initializes a new game and removes the victory sequence, leaving only the menu.
func _setup_game():
	remove_child(victory_sequence)
	_set_game_to_new_copy()
	add_child(game)
	remove_child(game)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Calculate audio stream volume given offsets
	audio_stream_player.volume_db = base_volume + player_volume_offset + tween_volume_offset
	# Listen for fullscreen input
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

# Transitions from the menu to the game. Remake the game if player won previously.
func menu_to_game():
	if Values.won:
		tween_transition([remove_child.bind(start_menu), add_child.bind(game), _set_game_to_new_copy, \
			switch_bgm.bind("Sun"), reduce_if_paused, game.pause_menu.options_menu.refresh])
	else:
		tween_transition([remove_child.bind(start_menu), add_child.bind(game), \
			switch_bgm.bind("Sun"), reduce_if_paused, _call_game_options_refresh])

# Transitions from game to menu.
func game_to_menu():
	tween_transition([remove_child.bind(game), add_child.bind(start_menu), \
	 switch_bgm.bind("Menu"), reset_music_volume, start_menu.options_menu.refresh])

# Transitions from the game to the victory screen. 
# Calls the transition to happen instantly without any fade out.
func game_to_victory():
	if Values.cheated:
		tween_transition([remove_child.bind(game), _set_game_to_new_copy, add_child.bind(start_menu), \
			switch_bgm.bind("Menu"), start_menu.options_menu.refresh], 1.0, true)
	else:
		tween_transition([remove_child.bind(game), _set_game_to_new_copy, add_child.bind(victory_sequence), \
			switch_bgm.bind("VictoryLeadIn"), victory_sequence.play_sequence], 0)

# Transitions from victory to menu. Uses a special transition screen.
func victory_to_menu():
	tween_transition([remove_child.bind(victory_sequence), add_child.bind(start_menu), \
	 switch_bgm.bind("Menu"), start_menu.options_menu.refresh], 1.0, true)

# Restarts music and sets game to a new copy.
func restart_game():
	tween_transition([switch_bgm.bind("Sun"), _set_game_to_new_copy, _add_game_as_child, unpause])

## Unpauses the game if it's paused.
func unpause():
	get_tree().paused = false

# Adds the game as child. Used so that "game" is the current value of the variable, instead of the 
#  value assigned at the moment of calling tween_transition. 
func _add_game_as_child():
	add_child(game)

# Tells the game's options menu to refresh its values.
func _call_game_options_refresh():
	game.pause_menu.options_menu.refresh()

# Sets the game to a new copy, resetting current run values in Values.
func _set_game_to_new_copy():
	Values.reset()
	game.queue_free()
	if game.get_parent() == self:
		remove_child(game)
	game = GAME_SCENE.instantiate()

# Transitions the interactive playback stream to a new clip.
func switch_bgm(clip_name : String):
	playback.switch_to_clip_by_name(clip_name)

# Tweens a transition by fading to a transition screen, executing method calls, and fading back in. 
# Can use a special fade screen for transitions out of victory screens.
func tween_transition(method_calls : Array[Callable], dur := 0.75, is_victory_to_menu := false):
	if can_transition:
		can_transition = false
		if level_switch_tween:
			level_switch_tween.kill()
		level_switch_tween = create_tween()
		
		var fade_rect := color_rect
		var sprite = animated_sprite_2d
		# Use victory transition visuals
		if is_victory_to_menu:
			fade_rect = victory_color_rect
			sprite = sprite_2d
		
		# Fade out to transition screen
		level_switch_tween.tween_property(fade_rect, "modulate:a", 1.0, dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		level_switch_tween.parallel().tween_property(sprite, "modulate:a", 1.0, dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			
		# Do method calls
		for callable : Callable in method_calls:
			level_switch_tween.tween_callback(callable)
		
		# Fade back in
		level_switch_tween.tween_property(fade_rect, "modulate:a", 0.0, dur * 0.67)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)\
			.set_delay(dur * 0.33)
		level_switch_tween.parallel().tween_property(sprite, "modulate:a", 0.0, dur * 0.67)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)\
			.set_delay(dur * 0.33)
		
		# Allow other transitions
		level_switch_tween.tween_property(self, "can_transition", true, 0.0)

# Reduces the music volume. Used when the game is paused.
func reduce_music_volume(duration := 0.75):
	if volume_tween:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.tween_property(self, "tween_volume_offset", -18.0, duration).set_ease(Tween.EASE_IN_OUT)

# Returns the music volume to normal if it's reduced.
func reset_music_volume():
	if volume_tween:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.tween_property(self, "tween_volume_offset", 0.0, 0.75).set_ease(Tween.EASE_OUT)

# Reduces the music volume if the game is paused. Used when transition into a paused game.
func reduce_if_paused():
	if get_tree().paused:
		reduce_music_volume()

# Calls custom quit function on quit requests.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


# Instead of quitting automatically, saves game and fades to black first.
func quit_game():
	reduce_music_volume(0.3)
	var tween := create_tween()
	tween.tween_callback(Values.save_user_data)
	tween.tween_property(self, "modulate", Color.BLACK, 0.3).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(get_tree().quit)
