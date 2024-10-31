class_name Values

# for saving and loading
static var config : ConfigFile = ConfigFile.new()
static var ENCRYPTION_KEY = PackedByteArray([1, 2, 3, 69, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
						   17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])
const SAVE_PATH = "user://user-data.cfg"
static var initialized = false

# user settings 
static var skip_cutscene = false
static var speedrun_mode = false
static var finished_tutorial = false

# user stats
static var best_time := -1.0
static var best_section_time_splits : Array[float] = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0]
static var pr_section_time_splits : Array[float] = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0]
static var max_section_reached : Tower.Weather = Tower.Weather.SUNNY
static var max_height_reached := 0
static var victory_count := 0

# current game stats
static var time := 0.0
static var cur_section : Tower.Weather = Tower.Weather.SUNNY
static var section_time_splits : Array[float] = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0]
static var section_times : Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
static var cheated := false
static var won := false

static func _print(
	arg0:Variant=null,
	arg1 :Variant=null,\
	arg2 :Variant=null,\
	arg3 :Variant=null,\
	arg4 :Variant=null,\
	arg5 :Variant=null,\
	arg6 :Variant=null,\
	arg7 :Variant=null,\
	arg8 :Variant=null,\
	arg9 :Variant=null) -> void:
	
	const verbose := true
	if verbose: 
		var args: Array[Variant] = [
		arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	  ].filter(func(value:Variant) -> bool: return value != null)

		var string:String = "%s ".repeat(args.size()).strip_edges() % args

		print(string)


static func toggle_speedrun_mode(on : bool):
	speedrun_mode = on
	skip_cutscene = on

static func increment_time(delta : float):
	if not won:
		time += delta
		update_section_times(cur_section)

static func update_height(height : float):
	max_height_reached = max(max_height_reached, height)

static func reach_section(section : Tower.Weather):
	if section > cur_section:
		cur_section = section
		update_section_splits(section)
		save_user_data()


static func update_section_times(section : Tower.Weather):
	var sec_index = int(section)
	section_times[sec_index] = time

static func update_section_splits(section : Tower.Weather):
	var sec_index = int(section) - 1 # We just finished section - 1
	section_time_splits[sec_index] = time
	
	# update best split if this split is better
	if best_section_time_splits[sec_index] == -1 or best_section_time_splits[sec_index] == 0:
		best_section_time_splits[sec_index] = section_time_splits[sec_index]
	else:
		best_section_time_splits[sec_index] = min(section_time_splits[sec_index], \
									best_section_time_splits[sec_index]) 
	
	# update max section if section is higher
	max_section_reached = max(max_section_reached, section)


static func win():
	won = true
	reach_section(Tower.Weather.VICTORY)
	# update best time if this time is better
	if time < best_time or best_time == -1:
		# new PR
		best_time = time
		# copy over splits for this PR
		for i in range(len(best_section_time_splits)):
			pr_section_time_splits[i] = section_time_splits[i]
	victory_count += 1
	skip_cutscene = not speedrun_mode
	save_user_data()

static func reset():
	time = 0.0
	cur_section = Tower.Weather.SUNNY
	section_time_splits.fill(-1.0)
	section_times.fill(0.0)
	won = false
	cheated = false

static func clear_user_data():
	config.clear()
	var err = config.save_encrypted(SAVE_PATH, ENCRYPTION_KEY)
	if err != OK:
		_print("ERROR CLEARING DATA: " + str(err))
	else:
		_print("CLEARING SUCCESSFUL")
	SceneManager.instance.get_tree().quit()

# saving and loading
static func save_user_data():
	#if cheated: return # Don't save any data from a run with dev tools involved
	config.set_value("settings", "finished_tutorial", finished_tutorial)
	config.set_value("settings", "speedrun_mode", speedrun_mode)
	config.set_value("settings", "master_volume", VolumeBar.master_volume)
	config.set_value("settings", "music_volume", VolumeBar.music_volume)
	config.set_value("settings", "sfx_volume", VolumeBar.sfx_volume)
	config.set_value("stats", "best_time", best_time)
	config.set_value("stats", "best_section_time_splits", best_section_time_splits)
	config.set_value("stats", "pr_section_time_splits", pr_section_time_splits)
	config.set_value("stats", "max_section_reached", max_section_reached)
	config.set_value("stats", "max_height_reached", max_height_reached)
	config.set_value("stats", "victory_count", victory_count)
	#var err = config.save(SAVE_PATH)
	var err = config.save_encrypted(SAVE_PATH, ENCRYPTION_KEY)
	if err != OK:
		_print("ERROR SAVING DATA: " + str(err))
	else:
		_print("SAVING SUCCESSFUL")

static func load_user_data():
	var err = config.load_encrypted(SAVE_PATH, ENCRYPTION_KEY)
	#var err = config.load(SAVE_PATH)
	if err != OK:
		_print("ERROR LOADING DATA: " + str(err))
	else:
		_print("LOADING SUCCESSFUL")
	for section: String in config.get_sections():
		_print(section, ":")
		for key: String in config.get_section_keys(section):
			var value = config.get_value(section, key)
			if value == null:
				_print("INVALID LOAD VALUE: " + section + ", " + key)
			else:
				_print("  ", key, ": ", value)
			match key:
				"finished_tutorial":
					finished_tutorial = value
				"speedrun_mode":
					speedrun_mode = value
				"best_time":
					best_time = value
				"best_section_time_splits":
					best_section_time_splits = value
				"pr_section_time_splits":
					pr_section_time_splits = value
				"max_section_reached":
					max_section_reached = value
				"max_height_reached":
					max_height_reached = value
				"victory_count":
					victory_count = value
				"master_volume":
					VolumeBar.master_volume = value
				"music_volume": 
					VolumeBar.music_volume = value
				"sfx_volume": 
					VolumeBar.sfx_volume = value
	initialized = true
