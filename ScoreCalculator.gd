extends RefCounted

const HOUSE_RADIUS = 325.25

static func remove_distances_outside_goal(distances):
	var distances_inside_goal = []
	for distance in distances:
		if distance <= HOUSE_RADIUS:
			distances_inside_goal.append(distance)
	return distances_inside_goal

static func calculate_scores(red_distances, yellow_distances, current_red_score, current_yellow_score):
	if not red_distances.is_empty() and yellow_distances.is_empty():
		current_red_score += red_distances.size()
	elif red_distances.is_empty() and not yellow_distances.is_empty():
		current_yellow_score += yellow_distances.size()
	elif not red_distances.is_empty() and not yellow_distances.is_empty():
		if red_distances[0] < yellow_distances[0]:
			for dist in red_distances:
				if dist < yellow_distances[0]:
					current_red_score += 1
		elif yellow_distances[0] < red_distances[0]:
			for dist in yellow_distances:
				if dist < red_distances[0]:
					current_yellow_score += 1
	return [current_red_score, current_yellow_score]
