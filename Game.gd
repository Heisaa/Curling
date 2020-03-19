extends Node

# Red player vars
var red_stones = []
var red_score_sprites = []
var red_played = 0
var red_score = 0

# Yellow player vars
var yellow_stones = []
var yellow_score_sprites = []
var yellow_played = 0
var yellow_score = 0

const max_stones = 4
var last_played = "yellow"
var game_over = false

onready var stone_scene = load("res://Stone/Stone.tscn")

func _ready():
	init_score()

func _process(_delta):
	if game_over:
		# Calculate points
		var red_distances = []
		var yellow_distance = []
		
		for stone in red_stones:
			if is_instance_valid(stone):
				red_distances.append(stone.global_position.distance_to($Goal.global_position))
		for stone in yellow_stones:
			if is_instance_valid(stone):
				yellow_distance.append(stone.global_position.distance_to($Goal.global_position))
		
		red_distances.sort()
		yellow_distance.sort()
		
		#
		# FIX
		#
		if red_distances[0] == yellow_distance[0]:
			print("Draw")
		elif red_distances[0] < yellow_distance[0] or yellow_distance.empty():
			print("Red wins")
		elif yellow_distance[0] < red_distances[0] or red_distances.empty():
			print("Yellow wins")
		
		# Reload game
		get_tree().reload_current_scene()
	else:
		play_round()
		

func play_round():
	# Check if stone should be spawned
	var still_and_dead = true 
	var combined = red_stones + yellow_stones
	for stone in combined:
		if is_instance_valid(stone):
			if not stone.is_still or not stone.is_dead:
				still_and_dead = false
	
	# Spawn stone for second closest player
	if still_and_dead:
		update_score()
		
		print(red_stones)
		print (yellow_stones)
		
		var closest_red = 2000
		for stone in red_stones:
			if is_instance_valid(stone):
				closest_red = min(stone.global_position.distance_to($Goal.global_position), closest_red)
			else:
				red_stones.erase(stone)
		
		var closest_yellow = 2000
		for stone in yellow_stones:
			if is_instance_valid(stone):
				closest_yellow = min(stone.global_position.distance_to($Goal.global_position), closest_yellow)
			else:
				yellow_stones.erase(stone)
			
		print("Closest red: " + str(closest_red) + " " + "Closest yellow: " + str(closest_yellow))
		# Check which stone to spawn or if game is over
		if red_played >= max_stones and yellow_played >= max_stones:
			game_over = true
		elif (closest_red < closest_yellow and yellow_played < max_stones) or red_played >= max_stones:
			create_yellow_stone()
		elif (closest_red > closest_yellow and red_played < max_stones) or yellow_played >= max_stones:
			create_red_stone()
		elif closest_red == closest_yellow and yellow_played < max_stones and red_played < max_stones:
			if last_played == "yellow":
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
		last_played = "red"

func create_yellow_stone():
	if yellow_played < max_stones:
		var stone = stone_scene.instance()
		stone.init("yellow")
		add_child(stone)
		$Rink.connect("body_exited", stone, "_on_Stone_body_exit")
		yellow_stones.append(stone)
		yellow_played += 1
		last_played = "yellow"

func init_score():
	for i in range(max_stones):
		var sprite = Sprite.new()
		sprite.position = Vector2((i * 50) + 30, 1530)
		sprite.scale = Vector2(0.4, 0.4)
		sprite.texture = load("res://Stone/RedStone.png")
		add_child(sprite)
		red_score_sprites.append(sprite)
	
	for i in range(max_stones):
		var sprite = Sprite.new()
		sprite.position = Vector2((i * -50) + 1050, 1530)
		sprite.scale = Vector2(0.4, 0.4)
		sprite.texture = load("res://Stone/YellowStone.png")
		add_child(sprite)
		yellow_score_sprites.append(sprite)

func update_score():
	for i in max_stones:
		if i > max_stones - red_played - 1:
			red_score_sprites[i].visible = false
		else:
			red_score_sprites[i].visible = true
			
		if i > max_stones - yellow_played - 1:
			yellow_score_sprites[i].visible = false
		else:
			yellow_score_sprites[i].visible = true
