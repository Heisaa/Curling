extends Node2D

var number_of_stones = 4
var number_of_ends = 4

const MAX_STONES = 10
const MIN_STONES = 1

const MAX_ENDS = 10
const MIN_ENDS = 2


# Called when the node enters the scene tree for the first time.
func _ready():
	$Panel/VBoxContainer/Vbox/HBoxContainer/StonesNr.set_text(str(number_of_stones))
	$Panel/VBoxContainer/VBoxContainer/HBoxContainer2/EndsNr.set_text(str(number_of_ends))



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
		$Panel/VBoxContainer/VBoxContainer2/HBoxContainer/PetanqueRules.pressed = false


func _on_PetanqueRules_toggled(button_pressed):
	if button_pressed:
		$Panel/VBoxContainer/VBoxContainer2/HBoxContainer/CurlingRules.pressed = false

func _on_StartButton_pressed():
	Global.stones = number_of_stones
	Global.ends = number_of_ends
	
	if $Panel/VBoxContainer/VBoxContainer2/HBoxContainer/CurlingRules.pressed:
		Global.mode = "Curling"
	else:
		Global.mode = "Pétanque"
	get_tree().change_scene("res://Game.tscn")
