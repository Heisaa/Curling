extends RigidBody2D

var is_picked = false
var is_dead = false
var is_still = true
var is_out = false

var mouse_drag_speed = 30
var last_velocity

onready var line_over = get_node("../LineOver")
onready var rink = get_node("../Rink")

func _ready():
	connect("body_entered",self, "_on_Stone_body_entered")
	connect("body_exited",self, "_on_Stone_body_exited")
	global_position = Vector2(540, 1700)
	last_velocity = linear_velocity 

func init(color):
	if color == "yellow":
		$Sprite.texture = load("res://Stone/YellowStone.png")
	elif color == "red":
		$Sprite.texture = load("res://Stone/RedStone.png")

func _physics_process(_delta):
	if is_out:
		$collisionshape.disabled = true
		linear_velocity = Vector2(0,0)
	# Move if picked
	if is_picked:
		linear_velocity = get_global_mouse_position() - global_position
		linear_velocity *= mouse_drag_speed
	
	# Dead if over line
	if global_position.y < line_over.global_position.y:
		is_picked = false
		is_dead = true
	
	# Check if still
	if last_velocity == linear_velocity:
		is_still = true
	else:
		is_still = false
	
	last_velocity = linear_velocity
	

# Sound
var play = true
func _on_Stone_body_entered(_body):
	
	$Hit.set_volume_db(0)
	_body.play = false
	if play:
		if last_velocity.length() > 1000:
			$Hit.play()
		else:
			$Hit.set_volume_db(translate_range(last_velocity.length(), 0, 1000, -30, 0))
			print($Hit.get_volume_db())
			$Hit.play()
			
		

func _on_Stone_body_exited(_body):
	_body.play = true
	

func _on_Stone_body_exit(body):
	if body.global_position.y < line_over.global_position.y:
		body.is_out = true
	else:
		body.is_picked = false
		body.global_position = Vector2(540, 1700)
		body.linear_velocity = Vector2(0,0)

# Input functions
func _input_event( _viewport, event, _shape_idx ):
	if _event_is_left_button(event) and event.pressed and not is_dead:
		is_picked = true

func _input(event):
	if _event_is_left_button(event) and not event.pressed:
		is_picked = false

# Utility functions
func _event_is_left_button(event):
	return event is InputEventMouseButton and event.button_index == BUTTON_LEFT    

func translate_range(value, leftMin, leftMax, rightMin, rightMax):
	# Figure out how 'wide' each range is
	var leftSpan = leftMax - leftMin
	var rightSpan = rightMax - rightMin

	# Convert the left range into a 0-1 range (float)
	var valueScaled = float(value - leftMin) / float(leftSpan)

	# Convert the 0-1 range into a value in the right range.
	return rightMin + (valueScaled * rightSpan)
