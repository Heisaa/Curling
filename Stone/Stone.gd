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
	global_position = Vector2(540, 1700)
	last_velocity = linear_velocity 

func init(color):
	if color == "yellow":
		$Sprite.texture = load("res://Stone/YellowStone.png")
	elif color == "red":
		$Sprite.texture = load("res://Stone/RedStone.png")

func _physics_process(_delta):
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
func _on_Stone_body_entered(_body):
	$Hit.play()

func _on_Stone_body_exit(body):
	if body.global_position.y < line_over.global_position.y:
		body.queue_free()
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

