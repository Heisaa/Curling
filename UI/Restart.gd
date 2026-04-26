extends Node

const FontSizes = preload("res://UI/FontSizes.gd")

func _ready():
	_apply_font_sizes()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()

func _apply_font_sizes():
	for control in $VBoxContainer.find_children("*", "Control", true, false):
		control.add_theme_font_size_override("font_size", FontSizes.DEFAULT)

	$VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/LabelWinner.add_theme_font_size_override("font_size", FontSizes.LARGE)
	$VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/LabelScore.add_theme_font_size_override("font_size", FontSizes.LARGE)

func _layout_for_viewport():
	var viewport_size = Vector2(get_viewport().get_visible_rect().size)
	$ColorRect.size = viewport_size
	$VBoxContainer.size = viewport_size

func show_final_score(final_score_array):
	var red_score = final_score_array[0]
	var yellow_score = final_score_array[1]
	
	var winner = "No Player Wins!"
	
	if red_score > yellow_score:
		winner = "Red Player Wins!"
	elif yellow_score > red_score:
		winner = "Yellow Player Wins!"
	else:
		winner = "It's a Draw"
	
	$VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/LabelWinner.set_text(winner)
	$VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/LabelScore.set_text(str(red_score) + " - " + str(yellow_score))


func _on_ButtonPlayAgain_pressed():
	get_tree().reload_current_scene()


func _on_ButtonMainMenu_pressed():
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
