extends Node2D

var number_of_stones = 4
var number_of_ends = 4

const MAX_STONES = 10
const MIN_STONES = 1

const MAX_ENDS = 10
const MIN_ENDS = 2
const FontSizes = preload("res://UI/FontSizes.gd")


# Called when the node enters the scene tree for the first time.
func _ready():
	_apply_font_sizes()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	$Panel/VBoxContainer/Vbox/HBoxContainer/StonesNr.set_text(str(number_of_stones))
	$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/EndsNr.set_text(str(number_of_ends))

func _apply_font_sizes():
	for control in $Panel.find_children("*", "Control", true, false):
		control.add_theme_font_size_override("font_size", FontSizes.DEFAULT)

	$Panel/VBoxContainer/TitleLabel.add_theme_font_size_override("font_size", FontSizes.TITLE)
	$Panel/VBoxContainer/Vbox/HBoxContainer/MinusStones.add_theme_font_size_override("font_size", FontSizes.LARGE)
	$Panel/VBoxContainer/Vbox/HBoxContainer/StonesNr.add_theme_font_size_override("font_size", FontSizes.LARGE)
	$Panel/VBoxContainer/Vbox/HBoxContainer/PlusStones.add_theme_font_size_override("font_size", FontSizes.LARGE)
	$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/MinusEnds.add_theme_font_size_override("font_size", FontSizes.LARGE)
	$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/EndsNr.add_theme_font_size_override("font_size", FontSizes.LARGE)
	$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/PlusEnds.add_theme_font_size_override("font_size", FontSizes.LARGE)

func _layout_for_viewport():
	var viewport_size = Vector2(get_viewport().get_visible_rect().size)
	$Panel.size = viewport_size
	$Panel/VBoxContainer.size = viewport_size


func _on_MinusStones_pressed():
	if number_of_stones > MIN_STONES:
		number_of_stones -= 1
		$Panel/VBoxContainer/Vbox/HBoxContainer/StonesNr.set_text(str(number_of_stones))


func _on_PlusStones_pressed():
	if number_of_stones < MAX_STONES:
		number_of_stones += 1
		$Panel/VBoxContainer/Vbox/HBoxContainer/StonesNr.set_text(str(number_of_stones))


func _on_MinusEnds_pressed():
	if number_of_ends > MIN_ENDS:
		number_of_ends -= 2
		$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/EndsNr.set_text(str(number_of_ends))


func _on_PlusEnds_pressed():
	if number_of_ends < MAX_ENDS:
		number_of_ends += 2
		$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/EndsNr.set_text(str(number_of_ends))

func _on_CurlingRules_toggled(button_pressed):
	if button_pressed:
		$Panel/VBoxContainer/VBoxContainer2/HBoxContainer/PetanqueRules.button_pressed = false


func _on_PetanqueRules_toggled(button_pressed):
	if button_pressed:
		$Panel/VBoxContainer/VBoxContainer2/HBoxContainer/CurlingRules.button_pressed = false

func _on_StartButton_pressed():
	Global.stones = number_of_stones
	Global.ends = number_of_ends
	
	if $Panel/VBoxContainer/VBoxContainer2/HBoxContainer/CurlingRules.pressed:
		Global.mode = "Curling"
	else:
		Global.mode = "Pétanque"
	get_tree().change_scene_to_file("res://Game.tscn")
