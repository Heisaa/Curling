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

# Other vars
var max_stones = Global.stones
var last_played = "yellow"
var end_over = false
var game_over = false
var waiting_for_restart = false
var end = 1
var ends_to_play = Global.ends
var mode = Global.mode

# Signals
signal red_score_changed
signal yellow_score_changed
signal final_score

onready var stone_scene = load("res://Stone/Stone.tscn")
onready var restart_scene = load("res://UI/Restart.tscn")

func _ready():
	connect("red_score_changed", $RedScore, "update_score")
	connect("yellow_score_changed", $YellowScore, "update_score")
	init_score()

func _process(_delta):
	
	if game_over:
		if not waiting_for_restart:
			var restart = restart_scene.instance()
			add_child(restart)
			connect("final_score", $Restart, "show_final_score")
			
			var final_score_array = [red_score, yellow_score]
			emit_signal("final_score", final_score_array)
			waiting_for_restart = true
	elif end_over:
		# Calculate points
		var red_distances = get_distances(red_stones, $Goal.global_position)
		var yellow_distances = get_distances(yellow_stones, $Goal.global_position)
		
		print("reds before")
		print(red_distances)
		print("yellow before")
		print(yellow_distances)
		
		if mode == "Curling":
			red_distances = remove_distances_outside_goal(red_distances)
			yellow_distances = remove_distances_outside_goal(yellow_distances)
		
		print("reds 2")
		print(red_distances)
		print("yellow 2")
		print(yellow_distances)
		
		var scores = calculate_scores(red_distances, yellow_distances, red_score, yellow_score)
		red_score = scores[0]
		yellow_score = scores[1]
		
		
#		print("reds after")
#		print(red_distances)
#		print("yellow after")
#		print(yellow_distance)
		
		emit_signal("red_score_changed", red_score)
		emit_signal("yellow_score_changed", yellow_score)
		
		end += 1
		end_over = false
		
		if end > ends_to_play:
			game_over = true
		
		# Reload game
		if not game_over:
			for stone in (red_stones + yellow_stones):
				stone.queue_free()
			
			red_stones.clear()
			yellow_stones.clear()
			red_played = 0
			yellow_played = 0
			
			if end % 2 == 0:
				# end is even
				last_played = "red"
			else:
				# end is odd
				last_played = "yellow"
		
	else:
		play_round()

func get_distances(stones, position):
	var distances = [];
	
	for stone in stones:
			if is_instance_valid(stone):
				distances.append(stone.global_position.distance_to(position))
	
	distances.sort()
	return distances

func remove_distances_outside_goal(distances):
	var distances_inside_goal = []
	for distance in distances:
				if distance < 325.25:
					distances_inside_goal.append(distance)
	return distances_inside_goal

func calculate_scores(red_distances, yellow_distances, current_red_score, current_yellow_score):
	print(red_distances)
	print(yellow_distances)
	if not red_distances.empty() and yellow_distances.empty():
		current_red_score += red_distances.size()
	elif red_distances.empty() and not yellow_distances.empty():
		current_yellow_score += yellow_distances.size()
	elif not red_distances.empty() and not yellow_distances.empty():
		if red_distances[0] < yellow_distances[0]:
			for dist in red_distances:
				if dist < yellow_distances[0]:
					current_red_score += 1
		elif yellow_distances[0] < red_distances[0]:
			for dist in yellow_distances:
				if dist < red_distances[0]:
					current_yellow_score += 1
	return [current_red_score, current_yellow_score]

func play_round():
	update_score()
	# Check if stone should be spawned
	var spawn_new_stone = true 
	var combined = red_stones + yellow_stones
	for stone in combined:
		if is_instance_valid(stone):
			if not stone.is_still or not stone.is_dead:
				spawn_new_stone = false
	
	# Spawn stone for second closest player
	if spawn_new_stone:
		
		var closest_red = 2000
		var filtered_red_stones = []
		
		for stone in red_stones:
			if is_instance_valid(stone) and stone.is_out == false:
				closest_red = min(stone.global_position.distance_to($Goal.global_position), closest_red)
				filtered_red_stones.append(stone)
		red_stones = filtered_red_stones
		
		
		var closest_yellow = 2000
		var filtered_yellow_stones = []
		
		for stone in yellow_stones:
			if is_instance_valid(stone) and stone.is_out == false:
				closest_yellow = min(stone.global_position.distance_to($Goal.global_position), closest_yellow)
				filtered_yellow_stones.append(stone)
		yellow_stones = filtered_yellow_stones
		
		
		if mode == "Pétanque":
			# Check which stone to spawn or if game is over
			if red_played >= max_stones and yellow_played >= max_stones:
				end_over = true
			elif (closest_red < closest_yellow and yellow_played < max_stones) or red_played >= max_stones:
				create_yellow_stone()
			elif (closest_red > closest_yellow and red_played < max_stones) or yellow_played >= max_stones:
				create_red_stone()
			elif closest_red == closest_yellow and yellow_played < max_stones and red_played < max_stones:
				if last_played == "yellow":
					create_red_stone()
				else:
					create_yellow_stone()
		
		elif mode == "Curling":
			if red_played >= max_stones and yellow_played >= max_stones:
				end_over = true
			elif last_played == "red":
				create_yellow_stone()
			else:
				create_red_stone()
			
		print("red stones:")
		print(red_stones)
		print("yellow stones:")
		print(yellow_stones)


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
