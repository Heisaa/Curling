extends Control

func isMouseIn():
	return 

func _ready():
	print(get_tree().current_scene)
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _process(delta):
	print(get_global_mouse_position())
	pass
