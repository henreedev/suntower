extends Control
class_name OptionsMenu

# Section icon images
const SUNNY_SECTION_ICON = preload("res://assets/image/menu/SectionIconSunny.png")
const STORM_SECTION_ICON = preload("res://assets/image/menu/SectionIconStorm.png")
const WIND_SECTION_ICON = preload("res://assets/image/menu/SectionIconWind.png")
const PEACE_SECTION_ICON = preload("res://assets/image/menu/SectionIconPeace.png")
const ESCAPE_SECTION_ICON = preload("res://assets/image/menu/SectionIconEscape.png")

var section_icons = [SUNNY_SECTION_ICON, STORM_SECTION_ICON, WIND_SECTION_ICON, \
	PEACE_SECTION_ICON, ESCAPE_SECTION_ICON]

# Best section icon showing weather of section
@onready var best_section_icon : TextureRect = %BestSectionIcon

# Speedrun mode
@onready var check_button : CheckButton = $TabContainer/Settings/MarginContainer/VolSliders/Speedrun/CheckButton
@onready var speedrun = $TabContainer/Speedrun
@onready var tab_container = $TabContainer

# Rich text labels for stats
# Best ever split labels
@onready var sun_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/StormSplit/StormSplit
@onready var storm_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/WindSplit/WindSplit
@onready var wind_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/PeaceSplit/PeaceSplit
@onready var peace_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/EscapeSplit/EscapeSplit

# Personal record split labels
@onready var pr_sun_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/StormSplit/PRStormSplit
@onready var pr_storm_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/WindSplit/PRWindSplit
@onready var pr_wind_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/PeaceSplit/PRPeaceSplit
@onready var pr_peace_split = $TabContainer/Speedrun/MarginContainer/VBoxContainer/EscapeSplit/PREscapeSplit

# Other stats
@onready var best_height = %BestHeight
@onready var beat_game = %BeatGame

# Congrats label
@onready var congratulations = %Congratulations

# Arrays for ease of population
@onready var best_splits = [sun_split, storm_split, wind_split, peace_split, null, null, null]
@onready var pr_splits = [pr_sun_split, pr_storm_split, pr_wind_split, pr_peace_split, null, null, null]

# Enum for picking text coloring effects
enum ColorSetting {PULSE_RED, PULSE_GREEN, RAINBOW, NONE}

# Strings storing BBCode effects
const WAVE_FX_PRE = "[wave amp=10.0 freq=4connected=1]"
const WAVE_FX_POST = "[/wave]"

const RAINBOW_FX_PRE = "[rainbow freq=1.0 sat=.4 val=1]"
const RAINBOW_FX_POST = "[/rainbow]"

const PULSE_RED_FX_PRE = "[pulse freq=1.0 color=#ff9283 ease=-2.0]"
const PULSE_GREEN_FX_PRE = "[pulse freq=1.0 color=#c3ff83 ease=-2.0]"
const PULSE_FX_POST = "[/pulse]"

# Suffix units 
const SEC = "sec."
const PIXELS = "px."

# Is the options menu open?
var active := false

# Tween for fading in/out
var tween : Tween

# Color to fade out to (causes a flash on fade out and in)
const FADE_COLOR = Color(5, 5, 5, 0)

# Hides the menu initially.
func _ready():
	visible = false
	modulate = FADE_COLOR

# Fades in or out.
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

# Updates options values and statistics.
func refresh():
	_refresh_speedrun_mode()
	_refresh_labels()

# Displays updated statistics information, applying effects and custom messages to certain labels.
func _refresh_labels():
	# Update the best split times
	for i in range(len(best_splits)):
		if best_splits[i] == null: continue
		var label : RichTextLabel = best_splits[i]
		var value = Values.best_section_time_splits[i]
		_set_rich_text_label(label, value, SEC, true, ColorSetting.NONE)
	
	# Update the personal record split times
	for i in range(len(pr_splits)):
		if pr_splits[i] == null: continue
		var label : RichTextLabel = pr_splits[i]
		var value = Values.pr_section_time_splits[i]
		_set_rich_text_label(label, value, SEC, true, ColorSetting.NONE)
	
	# Pick the congratulation message and color underneath the stats based on victories and height
	var congrats = "Good luck!"
	var congrats_color = ColorSetting.NONE
	
	# Custom messages for victories 1-9
	match Values.victory_count:
		9:
			congrats = "you must be andre. if not ill pay you $15"
			congrats_color = ColorSetting.RAINBOW
		8:
			congrats = "i think you've played the game more than me"
			congrats_color = ColorSetting.RAINBOW
		7:
			congrats = "77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777"
			congrats_color = ColorSetting.RAINBOW
		6:
			congrats = "how many fingers am i holding up?!"
			congrats_color = ColorSetting.RAINBOW
		5:
			congrats = "phew thank you. ur insane btw!"
			congrats_color = ColorSetting.RAINBOW
		4:
			congrats = "woah don't stop at 4 it's unlucky"
			congrats_color = ColorSetting.RAINBOW
		3:
			congrats = "you're ACTUALLY cracked"
			congrats_color = ColorSetting.RAINBOW
		2:
			congrats = "ur cracked wtf"
			congrats_color = ColorSetting.RAINBOW
		1:
			congrats = "Good job!"
			congrats_color = ColorSetting.RAINBOW
		_:
			# Victories 10+
			if Values.victory_count > 9:
				congrats = "you won."
				congrats_color = ColorSetting.RAINBOW
			else:
				# No victory; congrats based on best section reached
				match Values.max_section_reached:
					Tower.Weather.STORMY:
						congrats = "Stormy out there..."
					Tower.Weather.WINDY:
						congrats = "Windy out there..."
					Tower.Weather.PEACEFUL:
						congrats = "So close..."
					_:
						# Hasn't progressed past first section; shame or encourage them
						if Values.max_height_reached < 500 and Values.max_height_reached > 0:
							congrats = "you just got started... don't give up"
							congrats_color = ColorSetting.PULSE_RED
						else:
							congrats = "Give it a shot!"
							congrats_color = ColorSetting.PULSE_GREEN
	
	_set_rich_text_label(congratulations, congrats, "", true, congrats_color, true)
	
	# Text for whether the player has beaten the game
	var beat_game_text = "YES" if Values.victory_count > 0 else "not yet"
	
	# Suffix for counting multiple victories (e.g. "YES x2")
	if Values.victory_count > 1: beat_game_text += " x" + str(Values.victory_count)
	
	_set_rich_text_label(beat_game, beat_game_text, "", Values.victory_count > 0, ColorSetting.RAINBOW if Values.victory_count > 0 else ColorSetting.PULSE_RED)
	
	# Set the max height reached in pixels
	_set_rich_text_label(best_height, Values.max_height_reached, PIXELS, false, ColorSetting.NONE)
	
	# Set the best section icon
	best_section_icon.texture = section_icons[Values.max_section_reached]

# Returns an empty string for numbers <= 0, otherwise string conversion of value
func _to_str_blank_if_neg(val):
	if (val is int or val is float) and val <= 0:
		return ""
	return str(val)

# Sets a rich text label according to different effect options.
func _set_rich_text_label(rt_label : RichTextLabel, value, suffix : String, wiggle : bool, color : ColorSetting, center := false):
	var value_str := ""
	
	if value is float:
		value_str = _to_str_blank_if_neg(value)
		if value_str != "":
			value_str = value_str.pad_decimals(2)
	else:
		value_str = _to_str_blank_if_neg(value)
	if value_str != "":
		value_str += " " + suffix
	
	match color:
		ColorSetting.PULSE_RED:
			value_str = PULSE_RED_FX_PRE + value_str + PULSE_FX_POST
		ColorSetting.PULSE_GREEN:
			value_str = PULSE_GREEN_FX_PRE + value_str + PULSE_FX_POST
		ColorSetting.RAINBOW:
			value_str = RAINBOW_FX_PRE + value_str + RAINBOW_FX_POST
	
	if wiggle:
		value_str = WAVE_FX_PRE + value_str + WAVE_FX_POST
	if center:
		value_str = "[center]" + value_str + "[/center]"
	
	rt_label.text = value_str

# If values has speedrun mode on, then enable speedrun tab and check the button
func _refresh_speedrun_mode():
	check_button.set_pressed_no_signal(Values.speedrun_mode)
	tab_container.set_tab_disabled(2, not Values.speedrun_mode)

# Update values when the speedrun check button is toggled.
func _on_check_button_toggled(toggled_on):
	Values.toggle_speedrun_mode(toggled_on)
	_refresh_speedrun_mode()
