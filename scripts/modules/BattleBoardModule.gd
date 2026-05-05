extends Control

const MAX_GRID_SIZE := 5
const ENEMY_DATABASE_PATH := "res://data/enemies/enemy_database.json"
const ENEMY_BACK_IMAGE_PATH := "res://assets/enemies/dorso.png"
const DROP_SLOT_SCRIPT := preload("res://scripts/ui/DropSlot.gd")
const RESULT_TOKEN_SCRIPT := preload("res://scripts/ui/ResultToken.gd")
const DEFAULT_UNLOCKED_CELLS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(0, 2),
	Vector2i(1, 2),
	Vector2i(2, 2),
]

@export_range(1, MAX_GRID_SIZE, 1) var grid_size: int = MAX_GRID_SIZE
@export var unlocked_cells: Array[Vector2i] = DEFAULT_UNLOCKED_CELLS
@export var cell_size: Vector2 = Vector2(86.0, 86.0)
@export var cell_gap: float = 8.0
@export var active_cell_color: Color = Color(0.73, 0.16, 0.05, 1.0)
@export var border_color: Color = Color(0.08, 0.03, 0.02, 0.95)
@export var tray_slot_color: Color = Color(0.22, 0.26, 0.33, 1.0)

@onready var grid_layer: Control = $BoardArea/BoardVBox/BoardCenter/GridLayer
@onready var token_tray: HBoxContainer = $BoardArea/BoardVBox/ResultsPanel/ResultsMargin/ResultsVBox/TokenTray
@onready var enemy_card: PanelContainer = $EnemyArea/EnemyMargin/EnemyCard
@onready var enemy_name_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/EnemyName
@onready var enemy_image: TextureRect = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/EnemyImage
@onready var hp_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/StatsGrid/HpValue
@onready var strength_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/StatsGrid/StrengthValue
@onready var reward_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/StatsGrid/RewardValue

var current_results: Array[Dictionary] = []
var current_enemy: Dictionary = {}
var enemy_revealed := false

func _ready() -> void:
	_build_grid()
	randomize()
	enemy_card.gui_input.connect(_on_enemy_card_gui_input)
	_prepare_hidden_enemy()
	_build_result_tray()
	resized.connect(_on_resized)

func _on_resized() -> void:
	_build_grid()

func set_unlocked_cells(cells: Array[Vector2i]) -> void:
	unlocked_cells = cells
	_build_grid()

func unlock_cell(cell: Vector2i) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_size or cell.y >= grid_size:
		return
	if unlocked_cells.has(cell):
		return
	unlocked_cells.append(cell)
	_build_grid()

func set_roll_results(results: Array[Dictionary]) -> void:
	current_results.clear()
	for result in results:
		current_results.append(result.duplicate(true))
	_build_result_tray()
	_prepare_hidden_enemy()

func refresh_random_enemy() -> void:
	_prepare_hidden_enemy()

func _build_grid() -> void:
	if grid_layer == null:
		return
	for child in grid_layer.get_children():
		child.queue_free()

	var shape_width := grid_size * cell_size.x + (grid_size - 1) * cell_gap
	var shape_height := grid_size * cell_size.y + (grid_size - 1) * cell_gap
	grid_layer.custom_minimum_size = Vector2(shape_width, shape_height)
	grid_layer.size = grid_layer.custom_minimum_size

	for cell in unlocked_cells:
		var slot := _create_drop_slot(active_cell_color)
		slot.position = _get_cell_position(cell)
		slot.size = cell_size
		slot.custom_minimum_size = cell_size
		grid_layer.add_child(slot)

func _build_result_tray() -> void:
	if token_tray == null:
		return
	for child in token_tray.get_children():
		child.queue_free()
	for result in current_results:
		var slot := _create_drop_slot(tray_slot_color)
		slot.custom_minimum_size = Vector2(96, 96)
		token_tray.add_child(slot)
		var token := TextureRect.new()
		token.set_script(RESULT_TOKEN_SCRIPT)
		token.call("setup", result)
		slot.call("place_token", token)

func _get_cell_position(cell: Vector2i) -> Vector2:
	var x := cell.x * (cell_size.x + cell_gap)
	var y := cell.y * (cell_size.y + cell_gap)
	return Vector2(x, y)

func _prepare_hidden_enemy() -> void:
	current_enemy = _pick_random_enemy()
	enemy_revealed = false
	enemy_name_label.text = "Carta Coperta"
	hp_value_label.text = "-"
	strength_value_label.text = "-"
	reward_value_label.text = "-"
	if ResourceLoader.exists(ENEMY_BACK_IMAGE_PATH):
		enemy_image.texture = load(ENEMY_BACK_IMAGE_PATH)
	else:
		enemy_image.texture = null

func _reveal_enemy() -> void:
	if current_enemy.is_empty():
		_prepare_hidden_enemy()
	if current_enemy.is_empty():
		return
	enemy_revealed = true
	enemy_name_label.text = str(current_enemy.get("name", "Nemico"))
	hp_value_label.text = str(current_enemy.get("hp", 0))
	strength_value_label.text = str(current_enemy.get("strength", 0))
	reward_value_label.text = str(current_enemy.get("reward", 0))
	var image_path := str(current_enemy.get("image", ""))
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		enemy_image.texture = load(image_path)
	else:
		enemy_image.texture = null

func _pick_random_enemy() -> Dictionary:
	var enemies := _read_enemy_database()
	if enemies.is_empty():
		return {}
	return enemies[randi() % enemies.size()]

func _read_enemy_database() -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	var database_abs := ProjectSettings.globalize_path(ENEMY_DATABASE_PATH)
	if not FileAccess.file_exists(database_abs):
		return enemies
	var file := FileAccess.open(database_abs, FileAccess.READ)
	if file == null:
		return enemies
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				enemies.append(entry)
	return enemies

func _create_drop_slot(fill_color: Color) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.set_script(DROP_SLOT_SCRIPT)
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	slot.add_theme_stylebox_override("panel", style)
	return slot

func _on_enemy_card_gui_input(event: InputEvent) -> void:
	if enemy_revealed:
		return
	if not _all_results_placed():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_reveal_enemy()

func _all_results_placed() -> bool:
	for child in token_tray.get_children():
		if child is PanelContainer and child.has_method("has_token") and child.call("has_token"):
			return false
	return true
