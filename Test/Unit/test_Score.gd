extends 'res://addons/gut/test.gd'

var main_game = load("res://Game.gd")
var game = null

func before_each():
	game = main_game.new()

func after_each():
	game.free()

func test_remove_distances_outside_goal():
	var distances = [23, 55.3, 60, 104, 300, 350, 402, 2000323]
	var expected = [23, 55.3, 60, 104, 300]
	var result = game.remove_distances_outside_goal(distances)
	
	assert_eq(result, expected)

func test_calculate_scores_1():
	var red_distances = [30, 35, 53, 62, 86]
	var yellow_distances = [54, 56, 90]
	var red_score = 0
	var yellow_score = 0
	
	var expected = [3, 0]
	var result = game.calculate_scores(red_distances, yellow_distances, red_score, yellow_score)
	
	assert_eq(result, expected)

func test_calculate_scores_2():
	var red_distances = [54, 56, 90]
	var yellow_distances = [30, 35, 53, 62, 86]
	var red_score = 2
	var yellow_score = 2
	
	var expected = [2, 5]
	var result = game.calculate_scores(red_distances, yellow_distances, red_score, yellow_score)
	
	assert_eq(result, expected)
