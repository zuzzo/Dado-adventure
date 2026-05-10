extends Control

const ROOM_FILL := Color(0.92, 0.88, 0.79, 1.0)
const ROOM_OUTLINE := Color(0.22, 0.15, 0.1, 1.0)
const CORRIDOR_FILL := Color(0.9, 0.86, 0.76, 1.0)
const PARCHEMENT_BG := Color(0.74, 0.61, 0.46, 1.0)
const GRID_LINE := Color(0.36, 0.27, 0.18, 0.15)
const START_FILL := Color(0.27, 0.54, 0.28, 1.0)
const EXIT_FILL := Color(0.68, 0.18, 0.14, 1.0)
const KNIGHT_TEXTURE_PATH := "res://assets/characters/cavaliere_sprite-sheet.png"
const KNIGHT_STEP_AUDIO_PATH := "res://assets/Sound effect/passi_2.mp3"
const KNIGHT_FRAME_COUNT := 3
const KNIGHT_FRAME_TIME := 0.12
const KNIGHT_MOVE_DURATION := 1.05
const KNIGHT_ROOM_STOP_TIME := 0.2

var _map_size := Vector2i(8, 8)
var _rooms: Array = []
var _corridors: Array = []
var _graph := {}
var _start_room_index := -1
var _exit_room_index := -1
var _current_room_index := -1
var _unit_size := 40.0
var _padding := 24.0
var _corridor_width := 18.0
var _knight_texture: Texture2D
var _knight_sprite: TextureRect
var _knight_step_player: AudioStreamPlayer
var _knight_frame := 0
var _knight_time_accumulator := 0.0
var _knight_animating := false

func set_layout(map_size: Vector2i, rooms: Array, corridors: Array, graph: Dictionary, start_room_index: int, exit_room_index: int) -> void:
	_map_size = map_size
	_rooms = rooms.duplicate(true)
	_corridors = corridors.duplicate(true)
	_graph = graph.duplicate(true)
	_start_room_index = start_room_index
	_exit_room_index = exit_room_index
	_current_room_index = start_room_index
	_update_layout_scale()
	custom_minimum_size = Vector2(map_size.x, map_size.y) * _unit_size + Vector2.ONE * _padding * 2.0
	size = custom_minimum_size
	_update_knight_sprite()
	queue_redraw()

func _ready() -> void:
	_ensure_knight_sprite()
	_ensure_step_player()
	resized.connect(_on_resized)
	set_process(true)

func _on_resized() -> void:
	_update_layout_scale()
	custom_minimum_size = Vector2(_map_size.x, _map_size.y) * _unit_size + Vector2.ONE * _padding * 2.0
	size = custom_minimum_size
	_update_knight_sprite()
	queue_redraw()

func _process(delta: float) -> void:
	if not _knight_animating:
		return
	_knight_time_accumulator += delta
	if _knight_time_accumulator < KNIGHT_FRAME_TIME:
		return
	_knight_time_accumulator = 0.0
	_knight_frame = (_knight_frame + 1) % KNIGHT_FRAME_COUNT
	_apply_knight_frame()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event = event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _knight_animating:
		return
	var clicked_room = _get_room_index_at_position(mouse_event.position)
	if clicked_room < 0 or clicked_room == _current_room_index:
		return
	var room_path = _find_room_path(_current_room_index, clicked_room)
	if room_path.size() < 2:
		return
	_move_knight_to_room(room_path)

func _update_layout_scale() -> void:
	if _map_size.x <= 0 or _map_size.y <= 0:
		return
	var available_width = max(size.x, 800.0) - _padding * 2.0
	var available_height = max(size.y, 600.0) - _padding * 2.0
	var width_based = available_width / float(_map_size.x)
	var height_based = available_height / float(_map_size.y)
	_unit_size = clampf(min(width_based, height_based), 24.0, 48.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PARCHEMENT_BG, true)
	_draw_grid()
	_draw_corridors()
	_draw_rooms()

func _draw_grid() -> void:
	var grid_size = Vector2(_map_size.x, _map_size.y) * _unit_size
	for x in range(_map_size.x + 1):
		var px = _padding + float(x) * _unit_size
		draw_line(Vector2(px, _padding), Vector2(px, _padding + grid_size.y), GRID_LINE, 1.0)
	for y in range(_map_size.y + 1):
		var py = _padding + float(y) * _unit_size
		draw_line(Vector2(_padding, py), Vector2(_padding + grid_size.x, py), GRID_LINE, 1.0)

func _draw_corridors() -> void:
	for corridor in _corridors:
		if not (corridor is Dictionary):
			continue
		var points = corridor.get("points", [])
		if not (points is Array) or points.size() < 2:
			continue
		for i in range(points.size() - 1):
			var from_point = _grid_to_world_center(points[i])
			var to_point = _grid_to_world_center(points[i + 1])
			_draw_corridor_segment(from_point, to_point)

func _draw_corridor_segment(from_point: Vector2, to_point: Vector2) -> void:
	var min_x = min(from_point.x, to_point.x) - _corridor_width * 0.5
	var min_y = min(from_point.y, to_point.y) - _corridor_width * 0.5
	var width = absf(to_point.x - from_point.x)
	var height = absf(to_point.y - from_point.y)
	var rect_size = Vector2(maxf(width, _corridor_width), maxf(height, _corridor_width))
	var rect = Rect2(Vector2(min_x, min_y), rect_size)
	draw_rect(rect, CORRIDOR_FILL, true)
	var joint_rect = Rect2(to_point - Vector2.ONE * (_corridor_width * 0.5), Vector2.ONE * _corridor_width)
	draw_rect(joint_rect, CORRIDOR_FILL, true)

func _draw_rooms() -> void:
	for index in range(_rooms.size()):
		var room = _rooms[index]
		if not (room is Dictionary):
			continue
		var room_cells = room.get("cells", [])
		if not (room_cells is Array):
			continue
		_draw_room_shape(room_cells)
		var world_rect = _cell_rect_to_world(_get_marker_cell(room_cells))
		if index == _start_room_index:
			_draw_room_marker(world_rect, START_FILL, "I")
		elif index == _exit_room_index:
			_draw_room_marker(world_rect, EXIT_FILL, "U")

func _draw_room_shape(room_cells: Array) -> void:
	var cell_set := {}
	for cell in room_cells:
		cell_set[cell] = true
	for cell in room_cells:
		var cell_rect = _cell_rect_to_world(cell)
		draw_rect(cell_rect, ROOM_FILL, true)
	for cell in room_cells:
		var cell_rect = _cell_rect_to_world(cell)
		_draw_cell_outline(cell_rect, cell, cell_set)

func _draw_cell_outline(cell_rect: Rect2, cell: Vector2i, cell_set: Dictionary) -> void:
	var left = cell_rect.position.x
	var right = cell_rect.position.x + cell_rect.size.x
	var top = cell_rect.position.y
	var bottom = cell_rect.position.y + cell_rect.size.y
	if not cell_set.has(cell + Vector2i(-1, 0)):
		draw_line(Vector2(left, top), Vector2(left, bottom), ROOM_OUTLINE, 3.0)
	if not cell_set.has(cell + Vector2i(1, 0)):
		draw_line(Vector2(right, top), Vector2(right, bottom), ROOM_OUTLINE, 3.0)
	if not cell_set.has(cell + Vector2i(0, -1)):
		draw_line(Vector2(left, top), Vector2(right, top), ROOM_OUTLINE, 3.0)
	if not cell_set.has(cell + Vector2i(0, 1)):
		draw_line(Vector2(left, bottom), Vector2(right, bottom), ROOM_OUTLINE, 3.0)

func _draw_room_marker(room_rect: Rect2, color: Color, label: String) -> void:
	var marker_size = Vector2(38, 38)
	var marker_rect = Rect2(room_rect.position + Vector2(10, 10), marker_size)
	draw_rect(marker_rect, color, true)
	draw_rect(marker_rect, ROOM_OUTLINE, false, 2.0)
	var font = ThemeDB.fallback_font
	if font == null:
		return
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	var text_pos = marker_rect.position + Vector2((marker_rect.size.x - text_size.x) * 0.5, (marker_rect.size.y + text_size.y) * 0.5 - 4.0)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func _ensure_knight_sprite() -> void:
	if _knight_sprite != null:
		return
	if ResourceLoader.exists(KNIGHT_TEXTURE_PATH):
		_knight_texture = load(KNIGHT_TEXTURE_PATH)
	_knight_sprite = TextureRect.new()
	_knight_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knight_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_knight_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_knight_sprite)
	_apply_knight_frame()

func _ensure_step_player() -> void:
	if _knight_step_player != null:
		return
	_knight_step_player = AudioStreamPlayer.new()
	_knight_step_player.bus = "Master"
	if ResourceLoader.exists(KNIGHT_STEP_AUDIO_PATH):
		var step_stream = load(KNIGHT_STEP_AUDIO_PATH)
		if step_stream is AudioStreamMP3:
			step_stream.loop = true
		_knight_step_player.stream = step_stream
	add_child(_knight_step_player)

func _apply_knight_frame() -> void:
	if _knight_sprite == null or _knight_texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = _knight_texture
	var frame_width = int(_knight_texture.get_width() / KNIGHT_FRAME_COUNT)
	atlas.region = Rect2(frame_width * _knight_frame, 0, frame_width, _knight_texture.get_height())
	_knight_sprite.texture = atlas
	var draw_height = _unit_size * 1.8
	var aspect = float(frame_width) / float(max(1, _knight_texture.get_height()))
	var draw_width = draw_height * aspect
	_knight_sprite.custom_minimum_size = Vector2(draw_width, draw_height)
	_knight_sprite.size = _knight_sprite.custom_minimum_size

func _update_knight_sprite() -> void:
	_ensure_knight_sprite()
	if _knight_sprite == null:
		return
	if _current_room_index < 0 or _current_room_index >= _rooms.size():
		_knight_sprite.visible = false
		return
	_knight_sprite.visible = true
	_apply_knight_frame()
	var target_center = _grid_to_world_center(_get_room_anchor_cell(_current_room_index))
	_knight_sprite.position = target_center - _knight_sprite.size * 0.5

func _get_room_index_at_position(local_position: Vector2) -> int:
	for index in range(_rooms.size()):
		var room = _rooms[index]
		if not (room is Dictionary):
			continue
		var room_cells = room.get("cells", [])
		if not (room_cells is Array):
			continue
		for cell in room_cells:
			if _cell_rect_to_world(cell).has_point(local_position):
				return index
	return -1

func _move_knight_to_room(room_path: Array) -> void:
	if _knight_sprite == null or room_path.size() < 2:
		return
	_ensure_step_player()
	_knight_animating = true
	_knight_frame = 0
	_knight_time_accumulator = 0.0
	_apply_knight_frame()
	_play_step_audio()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	var current_cell = _get_room_anchor_cell(int(room_path[0]))
	_knight_sprite.position = _grid_to_world_center(current_cell) - _knight_sprite.size * 0.5
	for path_index in range(room_path.size() - 1):
		var from_room_index = int(room_path[path_index])
		var to_room_index = int(room_path[path_index + 1])
		var edge_path = _build_edge_cell_path(from_room_index, to_room_index, current_cell)
		if edge_path.size() < 2:
			continue
		var motion_points = _compress_cell_path(edge_path)
		var segment_duration = KNIGHT_MOVE_DURATION / float(max(1, motion_points.size() - 1))
		for point_index in range(1, motion_points.size()):
			var world_point = _grid_to_world_center(motion_points[point_index]) - _knight_sprite.size * 0.5
			tween.tween_property(_knight_sprite, "position", world_point, segment_duration)
		tween.tween_callback(_set_current_room_index.bind(to_room_index))
		if path_index < room_path.size() - 2:
			tween.tween_interval(KNIGHT_ROOM_STOP_TIME)
		current_cell = edge_path[edge_path.size() - 1]
	tween.finished.connect(_on_knight_move_finished)

func _on_knight_move_finished() -> void:
	_knight_animating = false
	_knight_frame = 0
	_apply_knight_frame()
	_stop_step_audio()

func _set_current_room_index(room_index: int) -> void:
	_current_room_index = room_index

func _play_step_audio() -> void:
	if _knight_step_player == null or _knight_step_player.stream == null:
		return
	_knight_step_player.pitch_scale = 1.0
	_knight_step_player.volume_db = -4.0
	_knight_step_player.play()

func _stop_step_audio() -> void:
	if _knight_step_player == null:
		return
	_knight_step_player.stop()

func _get_corridor_points_between(from_room_index: int, to_room_index: int) -> Array:
	for corridor in _corridors:
		if not (corridor is Dictionary):
			continue
		var from_index = int(corridor.get("from", -1))
		var to_index = int(corridor.get("to", -1))
		var points = corridor.get("points", [])
		if not (points is Array) or points.is_empty():
			continue
		if from_index == from_room_index and to_index == to_room_index:
			return points.duplicate()
		if from_index == to_room_index and to_index == from_room_index:
			var reversed_points: Array = points.duplicate()
			reversed_points.reverse()
			return reversed_points
	return []

func _find_room_path(from_room_index: int, to_room_index: int) -> Array:
	if from_room_index == to_room_index:
		return [from_room_index]
	var frontier: Array = [from_room_index]
	var came_from := {from_room_index: -1}
	while not frontier.is_empty():
		var current_room = int(frontier.pop_front())
		for neighbor in _graph.get(current_room, []):
			var neighbor_index = int(neighbor)
			if came_from.has(neighbor_index):
				continue
			came_from[neighbor_index] = current_room
			if neighbor_index == to_room_index:
				return _reconstruct_room_path(came_from, to_room_index)
			frontier.append(neighbor_index)
	return []

func _reconstruct_room_path(came_from: Dictionary, target_room_index: int) -> Array:
	var path: Array = []
	var current_room = target_room_index
	while current_room >= 0:
		path.append(current_room)
		current_room = int(came_from.get(current_room, -1))
	path.reverse()
	return path

func _build_edge_cell_path(from_room_index: int, to_room_index: int, start_cell: Vector2i) -> Array:
	var corridor_points = _get_corridor_points_between(from_room_index, to_room_index)
	if corridor_points.is_empty():
		return []
	var target_cell = _get_room_anchor_cell(to_room_index)
	var traversable := _build_traversable_cells(from_room_index, to_room_index, corridor_points)
	return _find_grid_path(start_cell, target_cell, traversable)

func _build_traversable_cells(from_room_index: int, to_room_index: int, corridor_points: Array) -> Dictionary:
	var traversable := {}
	for cell in _get_room_cells(from_room_index):
		traversable[cell] = true
	for cell in _get_room_cells(to_room_index):
		traversable[cell] = true
	for point_index in range(corridor_points.size() - 1):
		for cell in _expand_segment_cells(corridor_points[point_index], corridor_points[point_index + 1]):
			traversable[cell] = true
	return traversable

func _expand_segment_cells(from_point: Vector2i, to_point: Vector2i) -> Array:
	var cells: Array = []
	var step = Vector2i(int(sign(to_point.x - from_point.x)), int(sign(to_point.y - from_point.y)))
	var current = from_point
	cells.append(current)
	while current != to_point:
		current += step
		cells.append(current)
	return cells

func _find_grid_path(start_cell: Vector2i, target_cell: Vector2i, traversable: Dictionary) -> Array:
	if start_cell == target_cell:
		return [start_cell]
	var frontier: Array = [start_cell]
	var came_from := {start_cell: start_cell}
	while not frontier.is_empty():
		var current = frontier.pop_front() as Vector2i
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor = current + offset
			if not traversable.has(neighbor) or came_from.has(neighbor):
				continue
			came_from[neighbor] = current
			if neighbor == target_cell:
				return _reconstruct_cell_path(came_from, start_cell, target_cell)
			frontier.append(neighbor)
	return []

func _reconstruct_cell_path(came_from: Dictionary, start_cell: Vector2i, target_cell: Vector2i) -> Array:
	var path: Array = [target_cell]
	var current = target_cell
	while current != start_cell:
		current = came_from[current]
		path.append(current)
	path.reverse()
	return path

func _compress_cell_path(cell_path: Array) -> Array:
	if cell_path.size() <= 2:
		return cell_path.duplicate()
	var compressed: Array = [cell_path[0]]
	var previous_direction = Vector2i.ZERO
	for index in range(1, cell_path.size()):
		var previous_cell = cell_path[index - 1] as Vector2i
		var current_cell = cell_path[index] as Vector2i
		var direction = current_cell - previous_cell
		if previous_direction != Vector2i.ZERO and direction != previous_direction:
			compressed.append(previous_cell)
		previous_direction = direction
	compressed.append(cell_path[cell_path.size() - 1])
	return compressed

func _get_room_cells(room_index: int) -> Array:
	if room_index < 0 or room_index >= _rooms.size():
		return []
	return _rooms[room_index].get("cells", [])

func _get_room_anchor_cell(room_index: int) -> Vector2i:
	var room_cells = _get_room_cells(room_index)
	if room_cells.is_empty():
		return Vector2i.ZERO
	var room_center = _rooms[room_index].get("center", room_cells[0]) as Vector2i
	var best_cell = room_cells[0] as Vector2i
	var best_distance = 999999
	for cell in room_cells:
		var room_cell = cell as Vector2i
		var distance = absi(room_cell.x - room_center.x) + absi(room_cell.y - room_center.y)
		if distance < best_distance:
			best_distance = distance
			best_cell = room_cell
	return best_cell

func _get_room_world_center(room_index: int) -> Vector2:
	if room_index < 0 or room_index >= _rooms.size():
		return Vector2.ZERO
	var room_center = _rooms[room_index].get("center", Vector2i.ZERO) as Vector2i
	return _grid_to_world_center(room_center)

func _get_marker_cell(room_cells: Array) -> Vector2i:
	var best_cell = room_cells[0]
	var best_score = 999999
	for cell in room_cells:
		var score = cell.x * 1000 + cell.y
		if score < best_score:
			best_score = score
			best_cell = cell
	return best_cell

func _cell_rect_to_world(cell: Vector2i) -> Rect2:
	var position = Vector2(cell) * _unit_size + Vector2.ONE * _padding
	return Rect2(position, Vector2.ONE * _unit_size)

func _grid_to_world_center(point: Vector2i) -> Vector2:
	return Vector2(point) * _unit_size + Vector2.ONE * (_padding + _unit_size * 0.5)
