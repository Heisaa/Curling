extends RigidBody2D

var is_picked = false
var mouse_drag_speed = 20

func _on_Stone_input_event( viewport, event, shape_idx ):
    if _event_is_left_button(event) and event.pressed:
        is_picked = true

func _input(event):
    if _event_is_left_button(event) and not event.pressed:
        is_picked = false

func _event_is_left_button(event):
    return event is InputEventMouseButton and event.button_index == BUTTON_LEFT    

func _physics_process(delta):
    if is_picked:
        linear_velocity = get_global_mouse_position() - global_position
        linear_velocity *= mouse_drag_speed