extends Control

signal back_requested

const DEFAULT_MAP_SIZE := Vector2i(18, 12)
const SPECIAL_ROOM_TEMPLATES := [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
]

@onready var level_spin: SpinBox = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/LevelSpin
@onready var room_count_spin: SpinBox = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/RoomCountSpin
@onready var status_label: Label = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/StatusLabel
@onready var map_canvas: Control = $Margin/Root/RightPanel/RightMargin/RightVBox/MapScroll/MapCanvas

var _map_size := DEFAULT_MAP_SIZE
var _rooms: Array = []
var _corridors: Array = []
var _graph := {}
var _start_room_index := -1
var _exit_room_index := -1

func _ready() -> void:
	randomize()
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/BackButton.pressed.connect(_on_back_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/GenerateButton.pressed.connect(_on_generate_pressed)
	_generate_dungeon()

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_generate_pressed() -> void:
	_generate_dungeon()

func _generate_dungeon() -> void:
	var room_target = int(room_count_spin.value)
	_map_size = _estimate_map_size(room_target)
	_rooms.clear()
	_corridors.clear()
	_graph.clear()
	_start_room_index = -1
	_exit_room_index = -1
	var attempts = room_target * 30
	while _rooms.size() < room_target and attempts > 0:
		attempts -= 1
		_try_add_random_room()
	if _rooms.is_empty():
		_fail_generation("Impossibile generare stanze valide.")
		return
	_build_minimum_connectivity()
	_start_room_index = 0
	_choose_start_and_exit()
	map_canvas.call("set_layout", _map_size, _rooms, _corridors, _graph, _start_room_index, _exit_room_index)
	status_label.text = "Step 3: ingresso e uscita separati da %d stanze sul grafo." % _get_room_graph_distance(_start_room_index, _exit_room_index)

func _estimate_map_size(room_count: int) -> Vector2i:
	var width = max(14, room_count * 2 + 6)
	var height = max(10, int(ceili(float(room_count) * 1.2)) + 5)
	return Vector2i(width, height)

func _generate_room_shape() -> Array:
	if randf() <= 0.8:
		var width = randi_range(3, 5)
		var height = randi_range(3, 5)
		var cells: Array = []
		for y in range(height):
			for x in range(width):
				cells.append(Vector2i(x, y))
		return cells
	var template = SPECIAL_ROOM_TEMPLATES[randi() % SPECIAL_ROOM_TEMPLATES.size()]
	return _rotate_template(template, randi() % 4)

func _pick_room_origin(shape: Array) -> Vector2i:
	var bounds = _get_shape_bounds(shape)
	var min_x = 1
	var max_x = _map_size.x - bounds.x - 1
	var min_y = 1
	var max_y = _map_size.y - bounds.y - 1
	if max_x <= min_x or max_y <= min_y:
		return Vector2i(-1, -1)
	for _attempt in range(60):
		var room_x = randi_range(min_x, max_x)
		var room_y = randi_range(min_y, max_y)
		var placed_cells = _place_shape(shape, Vector2i(room_x, room_y))
		if _can_place_room(placed_cells):
			return Vector2i(room_x, room_y)
	return Vector2i(-1, -1)

func _place_shape(shape: Array, origin: Vector2i) -> Array:
	var placed: Array = []
	for point in shape:
		placed.append(origin + point)
	return placed

func _can_place_room(cells: Array) -> bool:
	for cell in cells:
		if cell.x < 1 or cell.y < 1 or cell.x >= _map_size.x - 1 or cell.y >= _map_size.y - 1:
			return false
	for room in _rooms:
		var other_cells = room.get("cells", [])
		for cell in cells:
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					if other_cells.has(cell + Vector2i(offset_x, offset_y)):
						return false
	return true

func _add_room(cells: Array) -> void:
	_rooms.append({
		"cells": cells,
		"center": _compute_room_center(cells)
	})

func _try_add_random_room() -> void:
	var room_shape = _generate_room_shape()
	var room_origin = _pick_room_origin(room_shape)
	if room_origin == Vector2i(-1, -1):
		return
	var room_cells = _place_shape(room_shape, room_origin)
	_add_room(room_cells)

func _build_minimum_connectivity() -> void:
	_graph.clear()
	_corridors.clear()
	for index in range(_rooms.size()):
		_graph[index] = []
	if _rooms.size() < 2:
		return
	var connected: Array = [0]
	var remaining: Array = []
	for index in range(1, _rooms.size()):
		remaining.append(index)
	while not remaining.is_empty():
		var best_from = -1
		var best_to = -1
		var best_distance = 999999
		for from_index in connected:
			for to_index in remaining:
				var distance = _room_distance(int(from_index), int(to_index))
				if distance < best_distance:
					best_distance = distance
					best_from = int(from_index)
					best_to = int(to_index)
		if best_from < 0 or best_to < 0:
			break
		_add_corridor(best_from, best_to)
		connected.append(best_to)
		remaining.erase(best_to)

func _add_corridor(from_index: int, to_index: int) -> void:
	if _graph.get(from_index, []).has(to_index):
		return
	var from_point = _get_room_connection_point(from_index, to_index)
	var to_point = _get_room_connection_point(to_index, from_index)
	var midpoint = Vector2i(to_point.x, from_point.y) if bool(randi() % 2) else Vector2i(from_point.x, to_point.y)
	_corridors.append({
		"from": from_index,
		"to": to_index,
		"points": [from_point, midpoint, to_point]
	})
	_graph[from_index].append(to_index)
	_graph[to_index].append(from_index)

func _compute_room_center(cells: Array) -> Vector2i:
	var sum_x = 0
	var sum_y = 0
	for cell in cells:
		sum_x += cell.x
		sum_y += cell.y
	return Vector2i(roundi(float(sum_x) / float(cells.size())), roundi(float(sum_y) / float(cells.size())))

func _room_distance(from_index: int, to_index: int) -> int:
	var from_center = _rooms[from_index]["center"] as Vector2i
	var to_center = _rooms[to_index]["center"] as Vector2i
	return absi(from_center.x - to_center.x) + absi(from_center.y - to_center.y)

func _get_room_connection_point(room_index: int, target_room_index: int) -> Vector2i:
	var room_cells = _rooms[room_index]["cells"] as Array
	var target_center = _rooms[target_room_index]["center"] as Vector2i
	var best_cell = room_cells[0]
	var best_distance = 999999
	for cell in room_cells:
		var edge_cell = false
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not room_cells.has(cell + offset):
				edge_cell = true
				break
		if not edge_cell:
			continue
		var distance = absi(cell.x - target_center.x) + absi(cell.y - target_center.y)
		if distance < best_distance:
			best_distance = distance
			best_cell = cell
	return best_cell

func _choose_start_and_exit() -> void:
	if _rooms.size() <= 1:
		_start_room_index = 0
		_exit_room_index = 0
		return
	var required_rooms_between = min(int(level_spin.value), max(0, _rooms.size() - 2))
	var required_distance = required_rooms_between + 1
	var best_start = 0
	var best_exit = 1
	var best_distance = -1
	for from_index in range(_rooms.size()):
		for to_index in range(_rooms.size()):
			if from_index == to_index:
				continue
			var distance = _get_room_graph_distance(from_index, to_index)
			if distance >= required_distance and distance > best_distance:
				best_distance = distance
				best_start = from_index
				best_exit = to_index
	if best_distance < 0:
		for from_index in range(_rooms.size()):
			for to_index in range(_rooms.size()):
				if from_index == to_index:
					continue
				var fallback_distance = _get_room_graph_distance(from_index, to_index)
				if fallback_distance > best_distance:
					best_distance = fallback_distance
					best_start = from_index
					best_exit = to_index
	_start_room_index = best_start
	_exit_room_index = best_exit

func _get_room_graph_distance(from_index: int, to_index: int) -> int:
	if from_index == to_index:
		return 0
	var visited := {from_index: true}
	var frontier: Array = [{"room": from_index, "distance": 0}]
	while not frontier.is_empty():
		var current = frontier.pop_front()
		var room_index = int(current["room"])
		var distance = int(current["distance"])
		for neighbor in _graph.get(room_index, []):
			var neighbor_index = int(neighbor)
			if visited.has(neighbor_index):
				continue
			if neighbor_index == to_index:
				return distance + 1
			visited[neighbor_index] = true
			frontier.append({"room": neighbor_index, "distance": distance + 1})
	return -1

func _rotate_template(template: Array, turns: int) -> Array:
	var rotated: Array = []
	for point in template:
		var current = point
		for _i in range(turns):
			current = Vector2i(-current.y, current.x)
		rotated.append(current)
	var min_x = 999
	var min_y = 999
	for point in rotated:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
	var normalized: Array = []
	for point in rotated:
		normalized.append(Vector2i(point.x - min_x, point.y - min_y))
	return normalized

func _get_shape_bounds(shape: Array) -> Vector2i:
	var max_x = 0
	var max_y = 0
	for point in shape:
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	return Vector2i(max_x + 1, max_y + 1)

func _fail_generation(message: String) -> void:
	status_label.text = message
	map_canvas.call("set_layout", _map_size, [], [], {}, -1, -1)
