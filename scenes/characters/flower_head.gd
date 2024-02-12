extends RigidBody2D

enum State {INACTIVE, EXTENDING, RETRACTING}


var state : State = State.INACTIVE
var segments := 15
var _set_transform 
var _target_angle : float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	move_towards_target()

func move_towards_target():
	if state == State.EXTENDING:
		_target_angle = get_angle_to(get_local_mouse_position())
		
		

func begin_extending(transform : Transform2D):
	if state == State.INACTIVE:
		state == State.EXTENDING
		_set_transform = transform
		 # spawn a pot at pot position

func _integrate_forces(state):
	if _set_transform:
		state.transform = _set_transform
		_set_transform = null

