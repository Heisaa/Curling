extends Node

var red_stones = []
var red_played = 0
var yellow_stones = []
var yellow_played = 0

var max_stones = 2

onready var stone_scene = load("res://Stone/Stone.tscn")

func _ready():
	create_red_stone()

func _process(_delta):
	# Check if stone should be spawned
	var still_and_dead = true 
	var combined = red_stones + yellow_stones
	for stone in combined:
		if is_instance_valid(stone):
			if not stone.is_still or not stone.is_dead:
				still_and_dead = false
	
	# Spawn stone for second closest player
	if still_and_dead:
		var closest_red = 2000
		for stone in red_stones:
			if is_instance_valid(stone):
				closest_red = min(stone.global_position.distance_to($Goal.global_position), closest_red)
		
		var closest_yellow = 2000
		for stone in yellow_stones:
			if is_instance_valid(stone):
				closest_yellow = min(stone.global_position.distance_to($Goal.global_position), closest_yellow)
				
		print("red: " + str(red_played) + " " + "yellow: " + str(yellow_played))
		
		if red_played >= max_stones and yellow_played >= max_stones:
			print("game over")
		elif (closest_red < closest_yellow and yellow_played < max_stones) or red_played >= max_stones:
			create_yellow_stone()
		elif (closest_red > closest_yellow and red_played < max_stones) or yellow_played >= max_stones:
			create_red_stone()
		elif closest_red == closest_yellow:
			if (red_played +  yellow_played) % 2 == 0:
				create_red_stone()
			else:
				create_yellow_stone()
		
	
func create_red_stone():
	if red_played < max_stones:
		var stone = stone_scene.instance()
		stone.init("red")
		add_child(stone)
		$Rink.connect("body_exited", stone, "_on_Stone_body_exit")
		red_stones.append(stone)
		red_played += 1

func create_yellow_stone():
	if yellow_played < max_stones:
		var stone = stone_scene.instance()
		stone.init("yellow")
		add_child(stone)
		$Rink.connect("body_exited", stone, "_on_Stone_body_exit")
		yellow_stones.append(stone)
		yellow_played += 1
