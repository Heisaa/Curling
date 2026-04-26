extends SceneTree

var failures = 0
var score_calculator = load("res://ScoreCalculator.gd")

func _init():
	test_remove_distances_outside_goal()
	test_remove_distances_outside_goal_keeps_boundary()
	test_calculate_scores_red_counts_until_first_yellow()
	test_calculate_scores_yellow_counts_until_first_red()
	test_calculate_scores_red_scores_when_yellow_empty()
	test_calculate_scores_yellow_scores_when_red_empty()
	test_calculate_scores_blank_end()
	test_calculate_scores_tied_closest_stone_scores_zero()
	
	if failures > 0:
		quit(1)
	else:
		print("Score tests passed")
		quit()

func assert_eq(actual, expected, test_name):
	if actual != expected:
		failures += 1
		push_error("%s failed. Expected %s, got %s" % [test_name, str(expected), str(actual)])

func test_remove_distances_outside_goal():
	var distances = [23, 55.3, 60, 104, 300, 350, 402, 2000323]
	var expected = [23, 55.3, 60, 104, 300]
	assert_eq(score_calculator.remove_distances_outside_goal(distances), expected, "test_remove_distances_outside_goal")

func test_remove_distances_outside_goal_keeps_boundary():
	var distances = [325.25, 325.26]
	var expected = [325.25]
	assert_eq(score_calculator.remove_distances_outside_goal(distances), expected, "test_remove_distances_outside_goal_keeps_boundary")

func test_calculate_scores_red_counts_until_first_yellow():
	var red_distances = [30, 35, 53, 62, 86]
	var yellow_distances = [54, 56, 90]
	var expected = [3, 0]
	assert_eq(score_calculator.calculate_scores(red_distances, yellow_distances, 0, 0), expected, "test_calculate_scores_red_counts_until_first_yellow")

func test_calculate_scores_yellow_counts_until_first_red():
	var red_distances = [54, 56, 90]
	var yellow_distances = [30, 35, 53, 62, 86]
	var expected = [2, 5]
	assert_eq(score_calculator.calculate_scores(red_distances, yellow_distances, 2, 2), expected, "test_calculate_scores_yellow_counts_until_first_red")

func test_calculate_scores_red_scores_when_yellow_empty():
	var expected = [5, 2]
	assert_eq(score_calculator.calculate_scores([30, 35, 53], [], 2, 2), expected, "test_calculate_scores_red_scores_when_yellow_empty")

func test_calculate_scores_yellow_scores_when_red_empty():
	var expected = [2, 4]
	assert_eq(score_calculator.calculate_scores([], [30, 35], 2, 2), expected, "test_calculate_scores_yellow_scores_when_red_empty")

func test_calculate_scores_blank_end():
	var expected = [2, 2]
	assert_eq(score_calculator.calculate_scores([], [], 2, 2), expected, "test_calculate_scores_blank_end")

func test_calculate_scores_tied_closest_stone_scores_zero():
	var expected = [2, 2]
	assert_eq(score_calculator.calculate_scores([30, 31], [30, 32], 2, 2), expected, "test_calculate_scores_tied_closest_stone_scores_zero")
