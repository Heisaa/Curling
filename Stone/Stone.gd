extends RigidBody2D

var is_picked = false
var is_dead = false
var is_still = true
var is_out = false

var mouse_drag_speed = 30
var last_velocity
var drag_position = Vector2.ZERO
var base_linear_damp = 1.2
var sweep_power = 0.0
var sweep_test_ice_intensity = 0.0
var ice_intensity_provider

const STONE_BOTTOM_MARGIN = 220.0
const SWEPT_LINEAR_DAMP = 0.01

@onready var line_over = get_node("../LineOver")
@onready var rink = get_node("../Rink")

func _ready():
	connect("body_entered", Callable(self, "_on_Stone_body_entered"))
	connect("body_exited", Callable(self, "_on_Stone_body_exited"))
	z_index = 2
	base_linear_damp = linear_damp
	global_position = _spawn_position()
	last_velocity = linear_velocity 

func init(color):
	if color == "yellow":
		$Sprite2D.texture = load("res://Stone/YellowStone.png")
	elif color == "red":
		$Sprite2D.texture = load("res://Stone/RedStone.png")

func _physics_process(delta):
	if is_out:
		$collisionshape.disabled = true
		linear_velocity = Vector2(0,0)
		sweep_power = 0.0
	# Move if picked
	if is_picked:
		linear_velocity = drag_position - global_position
		linear_velocity *= mouse_drag_speed
		sweep_power = 0.0
	
	# Dead if over line
	if global_position.y < line_over.global_position.y:
		is_picked = false
		is_dead = true

	_update_sweeping(delta)
	
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
	if is_instance_valid(_body) and _body.has_method("set_collision_sound_enabled"):
		_body.set_collision_sound_enabled(false)
	if play:
		if last_velocity.length() > 1000:
			$Hit.play()
		else:
			$Hit.set_volume_db(translate_range(last_velocity.length(), 0, 1000, -30, 0))
			$Hit.play()
			
		

func _on_Stone_body_exited(_body):
	if is_instance_valid(_body) and _body.has_method("set_collision_sound_enabled"):
		_body.set_collision_sound_enabled(true)
	

func handle_rink_exit(line_over_y):
	if global_position.y < line_over_y:
		is_out = true
	else:
		is_picked = false
		global_position = _spawn_position()
		linear_velocity = Vector2.ZERO

func set_collision_sound_enabled(enabled):
	play = enabled

func configure_sweep_test(start_position, start_velocity, ice_intensity):
	global_position = start_position
	linear_velocity = start_velocity
	is_picked = false
	is_dead = true
	is_still = false
	is_out = false
	sweep_power = 0.0
	sweep_test_ice_intensity = ice_intensity

# Input functions
func _input_event( _viewport, event, _shape_idx ):
	if _event_is_primary_press(event) and not is_dead:
		drag_position = _event_position_to_world(event.position)
		is_picked = true

func _input(event):
	if _event_is_primary_release(event):
		is_picked = false
	elif is_picked and _event_is_drag_motion(event):
		drag_position = _event_position_to_world(event.position)

# Utility functions
func _event_is_left_button(event):
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT

func _event_is_primary_press(event):
	return (_event_is_left_button(event) or event is InputEventScreenTouch) and event.pressed

func _event_is_primary_release(event):
	return (_event_is_left_button(event) or event is InputEventScreenTouch) and not event.pressed

func _event_is_drag_motion(event):
	return event is InputEventMouseMotion or event is InputEventScreenDrag

func _event_position_to_world(screen_position):
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func can_be_swept():
	return Global.mode == "Curling" and is_dead and not is_out and not is_picked and linear_velocity.length() > 0.0

func get_sweep_direction():
	if linear_velocity.length() <= 0.0:
		return Vector2.ZERO
	return linear_velocity.normalized()

func set_ice_intensity_provider(provider):
	ice_intensity_provider = provider

func _update_sweeping(_delta):
	var ice_intensity = 0.0
	if ice_intensity_provider != null and is_instance_valid(ice_intensity_provider):
		ice_intensity = ice_intensity_provider.get_fast_ice_intensity_at(global_position)
	sweep_power = max(sweep_test_ice_intensity, ice_intensity)
	linear_damp = lerp(base_linear_damp, SWEPT_LINEAR_DAMP, sweep_power)

func translate_range(value, leftMin, leftMax, rightMin, rightMax):
	# Figure out how 'wide' each range is
	var leftSpan = leftMax - leftMin
	var rightSpan = rightMax - rightMin

	# Convert the left range into a 0-1 range (float)
	var valueScaled = float(value - leftMin) / float(leftSpan)

	# Convert the 0-1 range into a value in the right range.
	return rightMin + (valueScaled * rightSpan)

func _spawn_position():
	var viewport_size = Vector2(get_viewport().get_visible_rect().size)
	return Vector2(viewport_size.x / 2.0, viewport_size.y - STONE_BOTTOM_MARGIN)
