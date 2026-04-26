extends Node2D

var stones = []
var fast_ice_samples = []
var sweep_feedback_strokes = []
var current_sweep_stroke
var time_since_last_sweep = 0.0
var sweep_feedback_power = 0.0

const SWEEP_LANE_HALF_WIDTH = 230.0
const SWEEP_AHEAD_DISTANCE = 340.0
const SWEEP_BEHIND_DISTANCE = 110.0
const SWEEP_MIN_MOTION = 8.0
const SWEEP_GAIN = 0.012
const SWEEP_FEEDBACK_DECAY = 1.6
const SWEEP_FEEDBACK_WIDTH = 92.0
const SWEEP_FEEDBACK_MAX_STROKES = 4
const SWEEP_FEEDBACK_STROKE_LIFETIME = 2.2
const SWEEP_FEEDBACK_POINT_SPACING = 10.0
const SWEEP_FEEDBACK_NEW_STROKE_DELAY = 0.45
const SWEEP_FEEDBACK_MIN_ALPHA = 0.18
const SWEEP_FEEDBACK_MAX_ALPHA = 0.48
const FAST_ICE_SAMPLE_RADIUS = 80.0
const FAST_ICE_SAMPLE_LIFETIME = 2.2
const FAST_ICE_SAMPLE_MERGE_RADIUS = 46.0
const FAST_ICE_SAMPLE_INTENSITY_GAIN = 0.22
const FAST_ICE_MAX_SAMPLES = 160
const SWEEP_TEST_FAST_ICE_LIFETIME = 8.0
const SWEEP_TEST_PATH_LENGTH = 1800.0
const SWEEP_TEST_PATH_START_DISTANCE = 600.0

func _process(delta):
	time_since_last_sweep += delta
	_update_fast_ice(delta)
	_update_sweep_feedback(delta)

func _input(event):
	if Global.mode != "Curling":
		return

	if event is InputEventScreenDrag:
		_try_sweep(event.position, event.relative)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_try_sweep(event.position, event.relative)

func register_stone(stone):
	if not stones.has(stone):
		stones.append(stone)
	if stone.has_method("set_ice_intensity_provider"):
		stone.set_ice_intensity_provider(self)

func reset_ice():
	fast_ice_samples.clear()
	sweep_feedback_power = 0.0
	current_sweep_stroke = null
	for stroke_data in sweep_feedback_strokes:
		if is_instance_valid(stroke_data.line):
			stroke_data.line.queue_free()
	sweep_feedback_strokes.clear()

func get_fast_ice_intensity_at(world_position):
	var strongest_intensity = 0.0
	for sample in fast_ice_samples:
		var distance = sample.position.distance_to(world_position)
		if distance > FAST_ICE_SAMPLE_RADIUS:
			continue

		var age_fade = 1.0 - clamp(sample.age / sample.lifetime, 0.0, 1.0)
		var distance_fade = 1.0 - clamp(distance / FAST_ICE_SAMPLE_RADIUS, 0.0, 1.0)
		strongest_intensity = max(strongest_intensity, sample.intensity * age_fade * distance_fade)

	return strongest_intensity

func create_sweep_test_path(start_position, start_velocity, ice_intensity):
	var direction = start_velocity.normalized()
	if direction == Vector2.ZERO:
		return

	var line = _create_feedback_line()
	var points = []
	var point_ages = []
	var point_intensities = []
	var path_length = _get_sweep_test_path_length(start_position, direction)
	var distance = SWEEP_TEST_PATH_START_DISTANCE
	while distance <= path_length:
		var point = start_position + direction * distance
		points.append(point)
		point_ages.append(0.0)
		point_intensities.append(ice_intensity)
		_add_fast_ice_sample(point, ice_intensity, SWEEP_TEST_FAST_ICE_LIFETIME)
		distance += SWEEP_FEEDBACK_POINT_SPACING

	var stroke_data = {
		"line": line,
		"points": points,
		"point_ages": point_ages,
		"point_intensities": point_intensities,
		"persistent": true,
	}
	sweep_feedback_strokes.append(stroke_data)
	_update_sweep_stroke_line(stroke_data)

func _try_sweep(screen_position, screen_relative):
	if screen_relative.length() < SWEEP_MIN_MOTION:
		return

	var world_position = _event_position_to_world(screen_position)
	if not _can_sweep_at(world_position):
		return

	var brush_intensity = min(1.0, screen_relative.length() * SWEEP_GAIN)
	sweep_feedback_power = min(1.0, sweep_feedback_power + brush_intensity)
	_show_sweep_feedback(world_position)
	time_since_last_sweep = 0.0

func _can_sweep_at(world_position):
	_prune_stones()
	for stone in stones:
		if stone.can_be_swept() and _is_position_in_sweep_lane(stone, world_position):
			return true
	return false

func _is_position_in_sweep_lane(stone, world_position):
	var forward_direction = stone.get_sweep_direction()
	if forward_direction == Vector2.ZERO:
		return false

	var offset = world_position - stone.global_position
	var forward_distance = offset.dot(forward_direction)
	var side_distance = abs(offset.dot(forward_direction.orthogonal()))

	return forward_distance >= -SWEEP_BEHIND_DISTANCE and forward_distance <= SWEEP_AHEAD_DISTANCE and side_distance <= SWEEP_LANE_HALF_WIDTH

func _show_sweep_feedback(world_position):
	var stroke_data = _get_current_sweep_stroke(world_position)
	var points = stroke_data.points
	if points[points.size() - 1].distance_to(world_position) < SWEEP_FEEDBACK_POINT_SPACING:
		return

	points.append(world_position)
	stroke_data.point_ages.append(0.0)
	var local_intensity = _add_brush_fast_ice_sample(world_position)
	stroke_data.point_intensities.append(local_intensity)
	_update_sweep_stroke_line(stroke_data)

	while sweep_feedback_strokes.size() > SWEEP_FEEDBACK_MAX_STROKES:
		var old_stroke = sweep_feedback_strokes.pop_front()
		if is_instance_valid(old_stroke.line):
			old_stroke.line.queue_free()
		if current_sweep_stroke == old_stroke:
			current_sweep_stroke = null

func _get_current_sweep_stroke(world_position):
	if current_sweep_stroke == null or not is_instance_valid(current_sweep_stroke.line) or time_since_last_sweep > SWEEP_FEEDBACK_NEW_STROKE_DELAY:
		var start_offset = Vector2.RIGHT
		var nearest_stone = _get_nearest_sweepable_stone(world_position)
		if nearest_stone != null:
			start_offset = nearest_stone.get_sweep_direction().orthogonal()

		current_sweep_stroke = {
			"line": _create_feedback_line(),
			"points": [world_position - start_offset, world_position + start_offset],
			"point_ages": [0.0, 0.0],
			"point_intensities": [sweep_feedback_power, sweep_feedback_power],
		}
		var local_intensity = _add_brush_fast_ice_sample(world_position)
		current_sweep_stroke.point_intensities[0] = local_intensity
		current_sweep_stroke.point_intensities[1] = local_intensity
		sweep_feedback_strokes.append(current_sweep_stroke)
		_update_sweep_stroke_line(current_sweep_stroke)

	return current_sweep_stroke

func _create_feedback_line():
	var line = Line2D.new()
	line.width = SWEEP_FEEDBACK_WIDTH
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.default_color = Color(0.82, 0.96, 1.0, SWEEP_FEEDBACK_MIN_ALPHA)
	add_child(line)
	return line

func _add_brush_fast_ice_sample(world_position):
	var brush_intensity = max(FAST_ICE_SAMPLE_INTENSITY_GAIN, sweep_feedback_power * FAST_ICE_SAMPLE_INTENSITY_GAIN)
	return _add_fast_ice_sample(world_position, brush_intensity, FAST_ICE_SAMPLE_LIFETIME)

func _add_fast_ice_sample(world_position, intensity, lifetime):
	for sample in fast_ice_samples:
		if sample.position.distance_to(world_position) <= FAST_ICE_SAMPLE_MERGE_RADIUS:
			sample.intensity = min(1.0, sample.intensity + intensity)
			sample.age = 0.0
			sample.lifetime = max(sample.lifetime, lifetime)
			return sample.intensity

	fast_ice_samples.append({
		"position": world_position,
		"age": 0.0,
		"intensity": intensity,
		"lifetime": lifetime,
	})

	while fast_ice_samples.size() > FAST_ICE_MAX_SAMPLES:
		fast_ice_samples.pop_front()

	return intensity

func _update_fast_ice(delta):
	var remaining_samples = []
	for sample in fast_ice_samples:
		sample.age += delta
		if sample.age < sample.lifetime:
			remaining_samples.append(sample)
	fast_ice_samples = remaining_samples

func _update_sweep_feedback(delta):
	sweep_feedback_power = max(0.0, sweep_feedback_power - SWEEP_FEEDBACK_DECAY * delta)

	var remaining_strokes = []
	for stroke_data in sweep_feedback_strokes:
		var line = stroke_data.line
		if not is_instance_valid(line):
			continue

		if stroke_data.get("persistent", false):
			_update_sweep_stroke_line(stroke_data)
			remaining_strokes.append(stroke_data)
			continue

		for i in range(stroke_data.point_ages.size()):
			stroke_data.point_ages[i] += delta

		while stroke_data.point_ages.size() > 0 and stroke_data.point_ages[0] >= SWEEP_FEEDBACK_STROKE_LIFETIME:
			stroke_data.point_ages.pop_front()
			stroke_data.points.pop_front()
			stroke_data.point_intensities.pop_front()

		if stroke_data.points.size() < 2:
			if current_sweep_stroke == stroke_data:
				current_sweep_stroke = null
			line.queue_free()
			continue

		_update_sweep_stroke_line(stroke_data)
		remaining_strokes.append(stroke_data)

	sweep_feedback_strokes = remaining_strokes

func _update_sweep_stroke_line(stroke_data):
	var line = stroke_data.line
	var points = PackedVector2Array()
	for point in stroke_data.points:
		points.append(point)
	line.points = points

	var gradient = Gradient.new()
	var point_count = stroke_data.points.size()
	for i in range(point_count):
		var fade = 1.0 - clamp(stroke_data.point_ages[i] / SWEEP_FEEDBACK_STROKE_LIFETIME, 0.0, 1.0)
		var offset = 0.0
		if point_count > 1:
			offset = float(i) / float(point_count - 1)
		var alpha = lerp(SWEEP_FEEDBACK_MIN_ALPHA, SWEEP_FEEDBACK_MAX_ALPHA, stroke_data.point_intensities[i])
		var color = Color(0.82, 0.96, 1.0, alpha * fade)
		if i == 0:
			gradient.set_color(0, color)
			gradient.set_offset(0, offset)
		else:
			gradient.add_point(offset, color)

	line.gradient = gradient

func _get_nearest_sweepable_stone(world_position):
	var nearest_stone = null
	var nearest_distance = INF
	_prune_stones()
	for stone in stones:
		if not stone.can_be_swept() or not _is_position_in_sweep_lane(stone, world_position):
			continue
		var distance = stone.global_position.distance_to(world_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_stone = stone
	return nearest_stone

func _get_sweep_test_path_length(start_position, direction):
	var viewport_size = Vector2(get_viewport().get_visible_rect().size)
	var path_length = SWEEP_TEST_PATH_LENGTH
	if direction.x < 0.0:
		path_length = max(path_length, start_position.x + SWEEP_FEEDBACK_WIDTH)
	elif direction.x > 0.0:
		path_length = max(path_length, viewport_size.x - start_position.x + SWEEP_FEEDBACK_WIDTH)

	if direction.y < 0.0:
		path_length = max(path_length, start_position.y + SWEEP_FEEDBACK_WIDTH)
	elif direction.y > 0.0:
		path_length = max(path_length, viewport_size.y - start_position.y + SWEEP_FEEDBACK_WIDTH)

	return path_length

func _event_position_to_world(screen_position):
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position

func _prune_stones():
	var active_stones = []
	for stone in stones:
		if is_instance_valid(stone):
			active_stones.append(stone)
	stones = active_stones
