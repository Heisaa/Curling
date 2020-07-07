extends Node

func show_final_score(final_score_array):
	var red_score = str(final_score_array[0])
	var yellow_score = str(final_score_array[1])
	
	var winner = "No Player Wins!"
	
	if red_score > yellow_score:
		winner = "Red Player Wins!"
	elif yellow_score > red_score:
		winner = "Yellow Player Wins!"
	else:
		winner = "It's a Draw"
	
	$VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/LabelWinner.set_text(winner)
	$VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/LabelScore.set_text(red_score + " - " + yellow_score)


func _on_ButtonPlayAgain_pressed():
	get_tree().reload_current_scene()


func _on_ButtonMainMenu_pressed():
	pass # Replace with function body.
