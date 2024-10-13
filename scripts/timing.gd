class_name Timing

static func create_timer(parent : Node, duration : float, runs_always := false):
	if duration <= 0: return
	var timer = Timer.new()
	if runs_always: timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.wait_time = duration
	parent.add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
