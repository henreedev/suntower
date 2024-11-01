extends Label
class_name TimeTracker

@export var section_type : Tower.Weather

const GOOD_COLOR = Color(0, 1, 0, 0.5)
const BAD_COLOR = Color(1, 0, 0, 0.5)
const OUTLINE_SIZE := 10

# The position laid out in editor, to return to when time is locked in
var initial_pos : Vector2

var active := false
var good_time := true
var outlined := false

var tint_tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_pos = position
	position = Vector2.ZERO # Parent should be in the correct spot
	visible = false
	scale = Vector2(0.5, 0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_time()

# Called when this timer's section is entered. Begins displaying time.
func activate():
	active = true
	visible = true

# Sets label text to the current split time for this timer's section; adjusts color if good or bad time
func update_time():
	if active and not Values.won: 
		var time = Values.section_times[section_type] # Assumed to be updated
		_set_text(time)
		_check_time_goodness(time)
	

# Sets the text of this label to the given float, with one decimal place. Stores the full value.
func _set_text(val : float):
	text = str(val).pad_decimals(1)

# Tweens text outline's color towards good or bad based on time. Removes outline if inactive. Switches goodness.
func _tint_text_outline(to_good := true, ignore_active:= false):
	# Reset the tint tween
	if tint_tween: tint_tween.kill()
	tint_tween = create_tween().set_parallel()
	
	if not active and not ignore_active:
		outlined = false
		tint_tween.tween_property(label_settings, "outline_size", 0, 2.0).set_trans(Tween.TRANS_CUBIC)
	else:
		outlined = true
		tint_tween.tween_property(label_settings, "outline_size", OUTLINE_SIZE, 2.0).set_trans(Tween.TRANS_CUBIC)
		if to_good:
			tint_tween.tween_property(label_settings, "outline_color", GOOD_COLOR, 2.0).set_trans(Tween.TRANS_CUBIC)
		else:
			tint_tween.tween_property(label_settings, "outline_color", BAD_COLOR, 2.0).set_trans(Tween.TRANS_CUBIC)

# Tints outline if time is close to best time.
func _check_time_goodness(time : float, compare_simply := false):
	var best_time = Values.best_section_time_splits[section_type] 
	if best_time == -1: return # no time stored for this section yet 
	
	var good = true
	if compare_simply:
		if time > best_time: # Bad
			if good_time:
				good_time = false
				_tint_text_outline(false, true)
		else: # Good 
			if not outlined:
				_tint_text_outline(true, true)
		return
	
	if abs(time - best_time) < 10.0:
		# Close to best time - determine if good or bad
		if time > best_time: # Bad
			if good_time:
				good_time = false
				_tint_text_outline(false)
		else: # Good - times are assumed good by default
			if not outlined:
				_tint_text_outline()

# Grabs the decided split time from Values, and displays it with two decimal places. Moves to side of screen. 
# Also deactivates this timer, unless it's Peaceful (then grows to middle of screen)
func lock_in_time():
	if active:
		active = false
		var locked_time = Values.section_time_splits[section_type]
		text = str(locked_time).pad_decimals(2)
		_check_time_goodness(locked_time, true)
		if section_type == Tower.Weather.PEACEFUL:
			# Remove tint
			_tint_text_outline()
			# Grow to center of screen (victory time)
			var tween = create_tween().set_parallel()
			tween.tween_property(self, "scale", Vector2.ONE * 2.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(self, "position", Vector2.ZERO - size / 2, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(get_parent(), "position", Vector2(1152/2, 684/2), 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(2.0)
			tween.tween_property(Main.instance.time_trackers[0], "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(Main.instance.time_trackers[1], "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(Main.instance.time_trackers[2], "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			
		else:
			# Move to the right side of the screen and shrink
			var tween = create_tween().set_parallel()
			create_tween().tween_property(self, "position", initial_pos, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)\
				.set_ease(Tween.EASE_OUT)
			create_tween().tween_property(self, "scale", Vector2(0.2, 0.2), 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)\
				.set_ease(Tween.EASE_OUT)
