extends Control

var direction = 0
var icon_color = Color.WHITE:
	set(value):
		icon_color = value
		queue_redraw()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	var width = size.x
	var height = size.y
	var stroke_width = 7.5
	var start = Vector2(width * 0.5, height * 0.78)
	var end = Vector2(width * (0.5 + direction * 0.26), height * 0.22)

	if direction == 0:
		draw_line(start, end, icon_color, stroke_width, true)
		draw_circle(start, 8.0, icon_color)
		draw_circle(end, 5.5, icon_color)
		return

	var control = Vector2(width * (0.5 + direction * 0.06), height * 0.48)
	var points = _path_points(start, control, end, 28)
	draw_polyline(points, icon_color, stroke_width, true)
	draw_circle(start, 8.0, icon_color)
	draw_circle(end, 5.5, icon_color)

func _path_points(start, control, end, point_count):
	var points = PackedVector2Array()
	for i in range(point_count):
		var t = float(i) / float(point_count - 1)
		points.append(_quadratic_point(start, control, end, t))
	return points

func _quadratic_point(start, control, end, t):
	var inverse = 1.0 - t
	return start * inverse * inverse + control * 2.0 * inverse * t + end * t * t
