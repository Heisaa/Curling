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
var sweep_test_started = false
var end = 1
var ends_to_play = Global.ends
var mode = Global.mode
var current_turn = ""
var hud_panel
var hud_panel_style
var hud_turn_dot_style
var hud_end_label
var hud_turn_label

const DESIGN_SIZE = Vector2(1080, 1920)
const GOAL_Y = 300.0
const LINE_OVER_BOTTOM_MARGIN = 420.0
const SCORE_BOTTOM_MARGIN = 350.0
const HUD_WIDTH = 620.0
const HUD_BOTTOM_MARGIN = 18.0
const HUD_BORDER_WIDTH = 14
const HUD_CORNER_RADIUS = 36
const SWEEP_TEST_STONE_SPEED = 940.0
const FontSizes = preload("res://UI/FontSizes.gd")
const ScoreCalculator = preload("res://ScoreCalculator.gd")

# Signals
signal red_score_changed
signal yellow_score_changed
signal final_score

@onready var stone_scene = load("res://Stone/Stone.tscn")
@onready var restart_scene = load("res://UI/Restart.tscn")
@onready var sweeping_controller = $SweepingController

func _ready():
	_apply_command_line_options()
	sweeping_controller.reset_ice()
	connect("red_score_changed", Callable($RedScore, "update_score"))
	connect("yellow_score_changed", Callable($YellowScore, "update_score"))
	$Rink.body_exited.connect(_on_rink_body_exited)
	_apply_font_sizes()
	init_score()
	_create_hud()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_update_hud()
	if Global.sweep_test:
		_start_sweep_test()

func _apply_command_line_options():
	for argument in OS.get_cmdline_user_args():
		if argument == "--sweep-test":
			Global.sweep_test = true
			Global.mode = "Curling"
			Global.stones = 4
			Global.ends = 1
			max_stones = Global.stones
			ends_to_play = Global.ends
			mode = Global.mode

func _process(_delta):
	if Global.sweep_test:
		return
	
	
	if game_over:
		if not waiting_for_restart:
			var restart = restart_scene.instantiate()
			add_child(restart)
			connect("final_score", Callable($Restart, "show_final_score"))
			
			var final_score_array = [red_score, yellow_score]
			emit_signal("final_score", final_score_array)
			waiting_for_restart = true
	elif end_over:
		# Calculate points
		var scores = calculate_end_scores()
		red_score = scores[0]
		yellow_score = scores[1]

		emit_signal("red_score_changed", red_score)
		emit_signal("yellow_score_changed", yellow_score)
		
		end += 1
		end_over = false
		
		if end > ends_to_play:
			game_over = true
		
		# Reload game
		if not game_over:
			for stone in (red_stones + yellow_stones):
				if is_instance_valid(stone):
					stone.queue_free()
			
			red_stones.clear()
			yellow_stones.clear()
			sweeping_controller.reset_ice()
			red_played = 0
			yellow_played = 0
			current_turn = ""
			
			if end % 2 == 0:
				# end is even
				last_played = "red"
			else:
				# end is odd
				last_played = "yellow"

		_update_hud()
			
	else:
		play_round()

func get_distances(stones, position):
	var distances = [];
	
	for stone in stones:
			if is_instance_valid(stone) and not stone.is_out:
				distances.append(stone.global_position.distance_to(position))
	
	distances.sort()
	return distances

func remove_distances_outside_goal(distances):
	return ScoreCalculator.remove_distances_outside_goal(distances)

func calculate_end_scores():
	var red_distances = get_distances(red_stones, $Goal.global_position)
	var yellow_distances = get_distances(yellow_stones, $Goal.global_position)
	
	if mode == "Curling":
		red_distances = remove_distances_outside_goal(red_distances)
		yellow_distances = remove_distances_outside_goal(yellow_distances)
	
	return calculate_scores(red_distances, yellow_distances, red_score, yellow_score)

func calculate_scores(red_distances, yellow_distances, current_red_score, current_yellow_score):
	return ScoreCalculator.calculate_scores(red_distances, yellow_distances, current_red_score, current_yellow_score)

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
			
func create_red_stone():
	if red_played < max_stones:
		var stone = stone_scene.instantiate()
		stone.init("red")
		add_child(stone)
		sweeping_controller.register_stone(stone)
		red_stones.append(stone)
		red_played += 1
		last_played = "red"
		current_turn = "Red"
		_update_hud()

func create_yellow_stone():
	if yellow_played < max_stones:
		var stone = stone_scene.instantiate()
		stone.init("yellow")
		add_child(stone)
		sweeping_controller.register_stone(stone)
		yellow_stones.append(stone)
		yellow_played += 1
		last_played = "yellow"
		current_turn = "Yellow"
		_update_hud()

func _start_sweep_test():
	if sweep_test_started:
		return

	sweep_test_started = true
	if hud_panel != null:
		hud_panel.visible = false
	$RedScore.visible = false
	$YellowScore.visible = false
	for sprite in red_score_sprites + yellow_score_sprites:
		sprite.visible = false

	var viewport_size = Vector2(get_viewport().get_visible_rect().size)
	viewport_size.x = max(viewport_size.x, DESIGN_SIZE.x)
	viewport_size.y = max(viewport_size.y, DESIGN_SIZE.y)
	var start_y = viewport_size.y - 260.0
	var lane_width = viewport_size.x / 5.0
	var intensities = [0.0, 0.25, 0.6, 1.0]
	var labels = ["No sweep", "Light", "Medium", "Heavy"]

	for i in range(intensities.size()):
		var stone = stone_scene.instantiate()
		stone.init("red")
		add_child(stone)
		sweeping_controller.register_stone(stone)

		var start_position = Vector2(lane_width * float(i + 1), start_y)
		var start_velocity = Vector2(0.0, -SWEEP_TEST_STONE_SPEED)
		stone.configure_sweep_test(start_position, start_velocity, intensities[i])
		if intensities[i] > 0.0:
			sweeping_controller.create_sweep_test_path(start_position, start_velocity, intensities[i])
		red_stones.append(stone)
		_create_sweep_test_label(labels[i], start_position + Vector2(-90.0, 95.0))

func _create_sweep_test_label(text, position):
	var label = Label.new()
	label.text = text
	label.position = position
	label.size = Vector2(180.0, 60.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FontSizes.DEFAULT)
	add_child(label)

func _on_rink_body_exited(body):
	if is_instance_valid(body) and body.has_method("handle_rink_exit"):
		body.handle_rink_exit($LineOver.global_position.y)

func init_score():
	for i in range(max_stones):
		var sprite = Sprite2D.new()
		sprite.scale = Vector2(0.4, 0.4)
		sprite.texture = load("res://Stone/RedStone.png")
		add_child(sprite)
		red_score_sprites.append(sprite)
	
	for i in range(max_stones):
		var sprite = Sprite2D.new()
		sprite.scale = Vector2(0.4, 0.4)
		sprite.texture = load("res://Stone/YellowStone.png")
		add_child(sprite)
		yellow_score_sprites.append(sprite)

func _apply_font_sizes():
	$RedScore.add_theme_font_size_override("font_size", FontSizes.SCORE)
	$YellowScore.add_theme_font_size_override("font_size", FontSizes.SCORE)
	if hud_end_label != null:
		hud_end_label.add_theme_font_size_override("font_size", 30)
		hud_turn_label.add_theme_font_size_override("font_size", 34)

func _create_hud():
	var hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)

	hud_panel = PanelContainer.new()
	hud_panel.name = "MatchStatus"
	hud_layer.add_child(hud_panel)

	hud_panel_style = StyleBoxFlat.new()
	hud_panel_style.bg_color = Color(0.05, 0.06, 0.06, 0.86)
	hud_panel_style.border_color = Color(1.0, 1.0, 1.0, 0.20)
	hud_panel_style.border_width_left = HUD_BORDER_WIDTH
	hud_panel_style.border_width_top = HUD_BORDER_WIDTH
	hud_panel_style.border_width_right = HUD_BORDER_WIDTH
	hud_panel_style.border_width_bottom = HUD_BORDER_WIDTH
	hud_panel_style.corner_radius_top_left = HUD_CORNER_RADIUS
	hud_panel_style.corner_radius_top_right = HUD_CORNER_RADIUS
	hud_panel_style.corner_radius_bottom_left = HUD_CORNER_RADIUS
	hud_panel_style.corner_radius_bottom_right = HUD_CORNER_RADIUS
	hud_panel.add_theme_stylebox_override("panel", hud_panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 8)
	hud_panel.add_child(margin)

	var layout = HBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var hud_turn_dot = Panel.new()
	hud_turn_dot.custom_minimum_size = Vector2(18.0, 18.0)
	hud_turn_dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hud_turn_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hud_turn_dot_style = StyleBoxFlat.new()
	hud_turn_dot_style.bg_color = Color.WHITE
	hud_turn_dot_style.corner_radius_top_left = 9
	hud_turn_dot_style.corner_radius_top_right = 9
	hud_turn_dot_style.corner_radius_bottom_left = 9
	hud_turn_dot_style.corner_radius_bottom_right = 9
	hud_turn_dot.add_theme_stylebox_override("panel", hud_turn_dot_style)
	layout.add_child(hud_turn_dot)

	hud_turn_label = Label.new()
	hud_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_turn_label.add_theme_color_override("font_color", Color.WHITE)
	layout.add_child(hud_turn_label)

	hud_end_label = Label.new()
	hud_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_end_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.90, 1.0))
	layout.add_child(hud_end_label)

	_apply_font_sizes()

func _update_hud():
	if hud_panel == null:
		return

	var turn_name = current_turn
	if game_over:
		turn_name = ""
		hud_turn_label.text = "Game Over"
	elif current_turn == "":
		turn_name = _get_next_turn_name()
		hud_turn_label.text = turn_name + " to throw"
	else:
		hud_turn_label.text = turn_name + " to throw"

	var turn_color = _get_turn_color(turn_name)
	hud_turn_dot_style.bg_color = turn_color
	hud_panel_style.border_color = turn_color

	hud_end_label.text = "End " + str(min(end, ends_to_play)) + "/" + str(ends_to_play)

func _get_turn_color(turn_name):
	if turn_name == "Red":
		return Color(1.0, 0.12, 0.10, 1.0)
	if turn_name == "Yellow":
		return Color(1.0, 0.88, 0.08, 1.0)
	return Color(1.0, 1.0, 1.0, 0.25)

func _layout_for_viewport():
	var viewport_size = Vector2(get_viewport().get_visible_rect().size)
	viewport_size.x = max(viewport_size.x, DESIGN_SIZE.x)
	viewport_size.y = max(viewport_size.y, DESIGN_SIZE.y)
	var center_x = viewport_size.x / 2.0
	var line_over_y = viewport_size.y - LINE_OVER_BOTTOM_MARGIN
	var score_y = viewport_size.y - SCORE_BOTTOM_MARGIN

	$Rink.position = viewport_size / 2.0
	$Rink/CollisionShape2D.shape.size = viewport_size
	$Rink/ColorRect.offset_left = -viewport_size.x / 2.0
	$Rink/ColorRect.offset_top = -viewport_size.y / 2.0
	$Rink/ColorRect.offset_right = viewport_size.x / 2.0
	$Rink/ColorRect.offset_bottom = viewport_size.y / 2.0

	$Goal.position = Vector2(center_x, GOAL_Y)
	$Goal/HorizontalGoal.points = PackedVector2Array([Vector2(-viewport_size.x / 2.0, 0), Vector2(viewport_size.x / 2.0, 0)])
	$Goal/Vertical.points = PackedVector2Array([Vector2(0, viewport_size.y - GOAL_Y), Vector2(0, -GOAL_Y)])

	$LineOver.position = Vector2(0, line_over_y)
	$LineOver.points = PackedVector2Array([Vector2(0, 0), Vector2(viewport_size.x, 0)])

	$RedScore.position = Vector2(5, score_y + 70)
	$YellowScore.position = Vector2(viewport_size.x - 105, score_y + 70)
	if hud_panel != null:
		var hud_width = min(viewport_size.x - 40.0, HUD_WIDTH)
		hud_panel.size = Vector2(hud_width, 0.0)
		var hud_height = hud_panel.get_combined_minimum_size().y
		hud_panel.position = Vector2(center_x - hud_width / 2.0, viewport_size.y - hud_height - HUD_BOTTOM_MARGIN)

	for i in range(red_score_sprites.size()):
		red_score_sprites[i].position = Vector2((i * 50) + 30, score_y)
	for i in range(yellow_score_sprites.size()):
		yellow_score_sprites[i].position = Vector2(viewport_size.x - 30 - (i * 50), score_y)

func _get_next_turn_name():
	if mode == "Curling":
		if last_played == "red":
			return "Yellow"
		return "Red"

	var closest_red = _get_closest_active_stone(red_stones)
	var closest_yellow = _get_closest_active_stone(yellow_stones)
	if red_played >= max_stones and yellow_played >= max_stones:
		return "No one"
	if (closest_red < closest_yellow and yellow_played < max_stones) or red_played >= max_stones:
		return "Yellow"
	if (closest_red > closest_yellow and red_played < max_stones) or yellow_played >= max_stones:
		return "Red"
	if last_played == "yellow":
		return "Red"
	return "Yellow"

func _get_closest_active_stone(stones):
	var closest = 2000.0
	for stone in stones:
		if is_instance_valid(stone) and stone.is_out == false:
			closest = min(stone.global_position.distance_to($Goal.global_position), closest)
	return closest

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
