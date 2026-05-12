extends Control

var path_points: PackedVector2Array = PackedVector2Array()
var back_color: Color = Color(0.08, 0.02, 0.01, 0.95)
var front_color: Color = Color(1.0, 0.62, 0.18, 1.0)
var back_width: float = 16.0
var front_width: float = 8.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_path_points(points: PackedVector2Array) -> void:
	path_points = points
	queue_redraw()

func _draw() -> void:
	if path_points.size() < 2:
		return
	draw_polyline(path_points, back_color, back_width, true)
	draw_polyline(path_points, front_color, front_width, true)
	for point in path_points:
		draw_circle(point, back_width * 0.38, back_color)
		draw_circle(point, front_width * 0.42, front_color)
