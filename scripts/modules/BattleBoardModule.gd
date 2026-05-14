extends Control

signal reroll_requested(count, cells)
signal character_hp_changed(hp)
signal player_stats_changed(hp, gold)

const MAX_GRID_SIZE := 5
const ENEMY_DATABASE_PATH := "res://data/enemies/enemy_database.json"
const ENEMY_BACK_IMAGE_PATH := "res://assets/enemies/dorso.png"
const TRACE_DEBUG_LOG_PATH := "res://trace_debug_log.txt"
const DURABILITY_BACKGROUND_PATHS := {
	"perennial": "res://assets/icone/ferro.png",
	"exhaustible": "res://assets/icone/legno.png",
	"ephemeral": "res://assets/icone/carta.png"
}
const ENEMY_ICON_PATHS := {
	"spada": "res://assets/icone/spada.png",
	"scudo": "res://assets/icone/scudo1.png",
	"cuore": "res://assets/icone/cuore1.png",
	"moneta": "res://assets/icone/moneta1.png",
	"magia": "res://assets/icone/magia1.png",
	"ladro": "res://assets/icone/ladro1.png",
	"arco": "res://assets/icone/arco1.png",
	"chiave": "res://assets/icone/chiave.png",
	"corona": "res://assets/icone/corona.png",
	"cristallo": "res://assets/icone/cristallo.png",
	"monete": "res://assets/icone/monete.png",
	"pergamena": "res://assets/icone/pergamena.png",
	"pozione": "res://assets/icone/pozione.png",
	"teschio": "res://assets/icone/teschio.png",
	"torcia": "res://assets/icone/torcia.png",
	"+1": "res://assets/icone/+1.png",
	"x2": "res://assets/icone/+1.png"
}
const DROP_SLOT_SCRIPT := preload("res://scripts/ui/DropSlot.gd")
const DRAG_PATH_OVERLAY_SCRIPT := preload("res://scripts/ui/DragPathOverlay.gd")
const RESULT_TOKEN_SCRIPT := preload("res://scripts/ui/ResultToken.gd")
const MODIFIER_SYMBOLS := {
	"+1": true,
	"x2": true
}
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
@export var highlight_cell_color: Color = Color(0.95, 0.38, 0.12, 1.0)
@export var exhausted_cell_color: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var reroll_target_cell_color: Color = Color(0.8, 0.6, 0.14, 1.0)
@export var border_color: Color = Color(0.08, 0.03, 0.02, 0.95)
@export var tray_slot_color: Color = Color(0.22, 0.26, 0.33, 1.0)

@onready var grid_layer: Control = $BoardArea/BoardVBox/BoardCenter/GridLayer
@onready var ability_label: Label = $BoardArea/BoardVBox/AbilityPanel/AbilityMargin/AbilityHBox/AbilityLabel
@onready var rest_button: Button = $BoardArea/BoardVBox/AbilityPanel/AbilityMargin/AbilityHBox/ActionButtons/RestButton
@onready var ability_button: Button = $BoardArea/BoardVBox/AbilityPanel/AbilityMargin/AbilityHBox/ActionButtons/AbilityButton
@onready var flee_button: Button = $BoardArea/BoardVBox/AbilityPanel/AbilityMargin/AbilityHBox/ActionButtons/FleeButton
@onready var token_tray: HBoxContainer = $BoardArea/BoardVBox/ResultsPanel/ResultsMargin/ResultsVBox/TokenTray
@onready var enemy_card: PanelContainer = $EnemyArea/EnemyMargin/EnemyCard
@onready var enemy_name_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/EnemyName
@onready var preview_card: Control = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard
@onready var enemy_image: TextureRect = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/EnemyImage
@onready var card_name_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardName
@onready var requirements_title_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/RequirementsTitle
@onready var requirements_row: HBoxContainer = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/RequirementsRow
@onready var damage_line_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/DamageLine
@onready var flee_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/FleeLine
@onready var reward_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/RewardLine
@onready var reveal_hint_label: Label = $EnemyArea/EnemyMargin/RevealHint
@onready var results_title_label: Label = $BoardArea/BoardVBox/ResultsPanel/ResultsMargin/ResultsVBox/ResultsTitle
var _drag_path_overlay: Control

var current_results: Array[Dictionary] = []
var current_enemy: Dictionary = {}
var current_enemy_requirements: Array = []
var enemy_revealed := false
var current_character_name: String = ""
var current_character_hp: int = 0
var current_character_mp: int = 0
var current_max_trace_length: int = 4
var current_character_ability: String = ""
var current_character_ability_effects: Array = []
var current_gold: int = 0
var current_arrows: int = 0
var current_equipment := {
	"weapon": {},
	"armor": {},
	"accessory": {}
}
var current_attack_bonus: int = 0
var current_weapon_damage_per_hit: int = 1
var current_weapon_attack_symbol: String = "spada"
var current_armor: int = 0
var current_pending_defense: int = 0
var current_enemy_blocks: int = 0
var _slot_by_cell: Dictionary = {}
var _hover_line_type: String = ""
var _hover_line_index: int = -1
var _exhausted_cells: Array = []
var _reroll_locked_cells: Array = []
var _pending_reroll_resolution: bool = false
var _pending_reroll_cells: Array = []
var _dragging_path: bool = false
var _drag_path: Array[Vector2i] = []
var _pending_status_messages: Array[String] = []
var _board_layout_locked: bool = false
var _current_enemy_sequence_summary: String = ""
var _object_header_container: VBoxContainer
var _object_header_icon_holder: Control
var _object_header_background: TextureRect
var _object_header_icon: TextureRect
var _object_header_label: Label
var _object_header_charges_label: Label

func _ready() -> void:
	_reset_trace_debug_log()
	_build_grid()
	_ensure_drag_path_lines()
	randomize()
	enemy_card.gui_input.connect(_on_enemy_card_gui_input)
	rest_button.pressed.connect(_on_rest_button_pressed)
	ability_button.pressed.connect(_on_ability_button_pressed)
	flee_button.pressed.connect(_on_flee_button_pressed)
	rest_button.disabled = true
	ability_button.disabled = true
	flee_button.disabled = true
	_set_children_mouse_ignore(enemy_card)
	_prepare_hidden_enemy()
	_build_result_tray()
	resized.connect(_on_resized)

func _input(event: InputEvent) -> void:
	_handle_trace_input(event)

func _unhandled_input(event: InputEvent) -> void:
	_handle_trace_input(event)

func _handle_trace_input(event: InputEvent) -> void:
	if not enemy_revealed or _pending_reroll_resolution:
		return
	if event is InputEventMouseButton:
		var mouse_button = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			var pressed_cell = _get_cell_at_global_position(mouse_button.global_position)
			_log_trace_debug("mouse_down global=%s cell=%s dragging=%s" % [str(mouse_button.global_position), str(pressed_cell), str(_dragging_path)])
			if pressed_cell != null:
				var slot = _slot_by_cell.get(pressed_cell, null) as PanelContainer
				_begin_drag_path(pressed_cell, slot)
			return
		if _dragging_path:
			_log_trace_debug("mouse_up path=%s" % str(_drag_path))
			_finalize_drag_path()
		return
	if event is InputEventMouseMotion and _dragging_path:
		var mouse_motion = event as InputEventMouseMotion
		if (mouse_motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return
		var hovered_cell = _get_cell_at_global_position(mouse_motion.global_position)
		_log_trace_debug("mouse_motion global=%s cell=%s path=%s" % [str(mouse_motion.global_position), str(hovered_cell), str(_drag_path)])
		if hovered_cell != null:
			_extend_drag_path(hovered_cell)

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
		current_results.append(_normalize_result_data(result))
	_exhausted_cells.clear()
	current_pending_defense = 0
	_reroll_locked_cells.clear()
	_pending_reroll_resolution = false
	_pending_reroll_cells.clear()
	_hover_line_type = ""
	_hover_line_index = -1
	_dragging_path = false
	_drag_path.clear()
	_pending_status_messages.clear()
	_board_layout_locked = false
	_build_result_tray()
	_prepare_hidden_enemy()
	_refresh_grid_visuals()
	_refresh_token_cost_states()

func set_character_context(character_name: String, hp: int, mp: int, max_trace_length: int, ability_text: String, ability_effects: Array = []) -> void:
	current_character_name = character_name
	current_character_hp = hp
	current_character_mp = mp
	current_max_trace_length = max(2, int(max_trace_length))
	current_character_ability = ability_text
	current_character_ability_effects = ability_effects.duplicate(true)
	_update_ability_label()
	_refresh_token_cost_states()
	player_stats_changed.emit(current_character_hp, current_gold)

func start_battle(character_name: String, hp: int, mp: int, max_trace_length: int, ability_text: String, ability_effects: Array, starting_loadout: Array, starting_objects: Array = []) -> void:
	set_character_context(character_name, hp, mp, max_trace_length, ability_text, ability_effects)
	var starting_results: Array[Dictionary] = []
	for entry in starting_loadout:
		var result = _create_loadout_result_data(entry)
		if not result.is_empty():
			starting_results.append(result)
	if starting_results.is_empty():
		starting_results.append(_create_loadout_result_data({"symbol_id": "spada"}))
	set_roll_results(starting_results)
	_apply_starting_objects(starting_objects)
	if results_title_label != null:
		results_title_label.text = "Simboli Da Piazzare"

func reset_run_state() -> void:
	current_gold = 0
	current_arrows = 0
	current_equipment = {
		"weapon": {},
		"armor": {},
		"accessory": {}
	}
	current_attack_bonus = 0
	current_weapon_damage_per_hit = 1
	current_weapon_attack_symbol = "spada"
	current_armor = 0
	current_pending_defense = 0
	current_enemy_blocks = 0
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)

func refresh_random_enemy() -> void:
	_prepare_hidden_enemy()

func _build_grid() -> void:
	if grid_layer == null:
		return
	_drag_path_overlay = null
	for child in grid_layer.get_children():
		child.queue_free()
	_slot_by_cell.clear()

	var min_x = 999
	var min_y = 999
	var max_x = -999
	var max_y = -999
	for cell in unlocked_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
		max_x = max(max_x, cell.x)
		max_y = max(max_y, cell.y)
	var used_columns = max(1, max_x - min_x + 1)
	var used_rows = max(1, max_y - min_y + 1)
	var shape_width = used_columns * cell_size.x + (used_columns - 1) * cell_gap
	var shape_height = used_rows * cell_size.y + (used_rows - 1) * cell_gap
	grid_layer.custom_minimum_size = Vector2(shape_width, shape_height)
	grid_layer.size = grid_layer.custom_minimum_size
	var grid = GridContainer.new()
	grid.columns = used_columns
	grid.custom_minimum_size = Vector2(shape_width, shape_height)
	grid.size = grid.custom_minimum_size
	grid.add_theme_constant_override("h_separation", int(cell_gap))
	grid.add_theme_constant_override("v_separation", int(cell_gap))
	grid_layer.add_child(grid)
	for row in used_rows:
		for column in used_columns:
			var original_cell = Vector2i(column + min_x, row + min_y)
			if unlocked_cells.has(original_cell):
				var slot := _create_drop_slot(active_cell_color)
				slot.custom_minimum_size = cell_size
				slot.set_meta("board_module", self)
				slot.gui_input.connect(_on_grid_slot_gui_input.bind(slot, original_cell))
				slot.mouse_entered.connect(_on_grid_slot_mouse_entered.bind(original_cell))
				slot.mouse_exited.connect(_on_grid_slot_mouse_exited)
				grid.add_child(slot)
				_slot_by_cell[original_cell] = slot
			else:
				var spacer := Control.new()
				spacer.custom_minimum_size = cell_size
				grid.add_child(spacer)
	_ensure_drag_path_lines()
	_refresh_grid_visuals()
	_refresh_board_token_drag_state()

func _build_result_tray() -> void:
	if token_tray == null:
		return
	for child in token_tray.get_children():
		token_tray.remove_child(child)
		child.queue_free()
	for result in current_results:
		var slot := _create_drop_slot(tray_slot_color)
		slot.custom_minimum_size = Vector2(96, 96)
		slot.set_meta("remove_when_empty", true)
		token_tray.add_child(slot)
		var token := TextureRect.new()
		token.set_script(RESULT_TOKEN_SCRIPT)
		token.call("setup", result)
		slot.call("place_token", token)

func _prepare_hidden_enemy(hint_text: String = "Piazza tutti i simboli, poi clicca la carta a destra per scoprire il nemico.") -> void:
	current_enemy = _pick_random_enemy()
	current_enemy_requirements.clear()
	current_pending_defense = 0
	current_enemy_blocks = 0
	_current_enemy_sequence_summary = ""
	var raw_requirements = current_enemy.get("requirements", [])
	if raw_requirements is Array:
		for requirement in raw_requirements:
			current_enemy_requirements.append(str(requirement))
	enemy_revealed = false
	enemy_name_label.text = "Carta Coperta"
	card_name_label.text = "Carta Coperta"
	_update_battle_card_header(false)
	card_name_label.visible = true
	requirements_title_label.visible = true
	requirements_row.visible = true
	damage_line_label.text = ""
	damage_line_label.visible = false
	flee_value_label.text = "Fuga: -"
	reward_value_label.text = "Premio: -"
	flee_value_label.visible = false
	reward_value_label.visible = false
	reveal_hint_label.text = hint_text
	rest_button.disabled = true
	ability_button.disabled = true
	flee_button.disabled = true
	_refresh_board_token_drag_state()
	_clear_requirements_row()
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
	card_name_label.text = enemy_name_label.text
	var enemy_damage = int(current_enemy.get("enemy_damage", 0))
	var is_object = str(current_enemy.get("category", "")) == "object"
	if is_object:
		enemy_damage = 0
	_update_battle_card_header(false)
	var object_durability_mode = str(current_enemy.get("granted_durability_mode", "exhaustible")).strip_edges().to_lower()
	var object_icons_only = is_object and object_durability_mode == "ephemeral" and _get_enemy_meta_text(enemy_damage).is_empty()
	requirements_title_label.visible = not is_object
	requirements_row.visible = not is_object or object_icons_only
	damage_line_label.visible = object_icons_only or is_object or enemy_damage > 0
	damage_line_label.text = _get_enemy_meta_text(enemy_damage)
	if object_icons_only:
		damage_line_label.visible = false
		_build_object_granted_icons_row()
	if is_object:
		damage_line_label.add_theme_font_size_override("font_size", 28)
		damage_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		damage_line_label.remove_theme_font_size_override("font_size")
		damage_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	flee_value_label.text = "Fuga: %s" % str(current_enemy.get("flee_text", "-"))
	reward_value_label.text = "Premio: %s" % str(current_enemy.get("reward_text", "-"))
	flee_value_label.visible = false
	reward_value_label.visible = false
	reveal_hint_label.text = "Nemico scoperto. Traccia una linea ortogonale di 2 fino a %d caselle per attaccare." % current_max_trace_length
	rest_button.disabled = false
	ability_button.disabled = false
	flee_button.disabled = false
	_refresh_board_token_drag_state()
	_log_trace_debug("enemy_revealed name=%s board_tokens=%d max_trace=%d" % [str(current_enemy.get("name", "")), _count_board_tokens(), current_max_trace_length])
	_build_requirements_row()
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
	if not FileAccess.file_exists(ENEMY_DATABASE_PATH):
		return enemies
	var file := FileAccess.open(ENEMY_DATABASE_PATH, FileAccess.READ)
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
	if _pending_reroll_resolution:
		reveal_hint_label.text = "Prima riposiziona i dadi rilanciati negli slot consentiti."
		return
	if enemy_revealed:
		return
	if not _all_results_placed():
		reveal_hint_label.text = "Prima piazza tutti i simboli nella griglia, poi clicca la carta."
		return
	reveal_hint_label.text = "Clicca la carta per scoprire il nemico."
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_reveal_enemy()

func _all_results_placed() -> bool:
	for child in token_tray.get_children():
		if child is PanelContainer and child.has_method("has_token") and child.call("has_token"):
			return false
	return true

func _build_requirements_row() -> void:
	_clear_requirements_row()
	for requirement in current_enemy_requirements:
		var icon_id = str(requirement)
		var icon_path = str(ENEMY_ICON_PATHS.get(icon_id, ""))
		if icon_path.is_empty():
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(62, 62)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.tooltip_text = icon_id.capitalize()
		requirements_row.add_child(icon)

func _clear_requirements_row() -> void:
	for child in requirements_row.get_children():
		child.queue_free()

func _set_children_mouse_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_ignore(child)

func can_drop_token_into_slot(slot: PanelContainer, token: Control) -> bool:
	if token == null:
		return false
	if _board_layout_locked and not _pending_reroll_resolution:
		return false
	if token.has_method("get_result_data"):
		var data = token.call("get_result_data") as Dictionary
		var allowed_cells = data.get("allowed_cells", [])
		if allowed_cells is Array and not allowed_cells.is_empty():
			var target_cell = _get_cell_for_slot(slot)
			if target_cell == null:
				return false
			return allowed_cells.has(target_cell)
	return true

func apply_rerolled_results(cells: Array, results: Array) -> void:
	if cells.is_empty():
		return
	_pending_reroll_resolution = true
	_pending_reroll_cells = cells.duplicate(true)
	_reroll_locked_cells = cells.duplicate(true)
	_refresh_board_token_drag_state()
	for result in results:
		var token := TextureRect.new()
		token.set_script(RESULT_TOKEN_SCRIPT)
		var result_data = _normalize_result_data(result)
		result_data["allowed_cells"] = cells.duplicate(true)
		token.call("setup", result_data)
		var tray_slot := _create_drop_slot(tray_slot_color)
		tray_slot.custom_minimum_size = Vector2(96, 96)
		tray_slot.set_meta("remove_when_empty", true)
		token_tray.add_child(tray_slot)
		tray_slot.call("place_token", token)
	reveal_hint_label.text = "Riposiziona i dadi rilanciati solo negli slot da cui provenivano."

func _get_cell_for_slot(slot: PanelContainer):
	for cell in _slot_by_cell.keys():
		if _slot_by_cell[cell] == slot:
			return cell
	return null

func _on_grid_slot_gui_input(event: InputEvent, slot: PanelContainer, cell: Vector2i) -> void:
	pass

func _on_grid_slot_mouse_exited() -> void:
	if not _dragging_path:
		_set_hover_line("", -1)

func _on_grid_slot_mouse_entered(cell: Vector2i) -> void:
	pass

func _get_cell_at_global_position(global_position: Vector2):
	for cell in _slot_by_cell.keys():
		var slot = _slot_by_cell[cell] as Control
		if slot == null:
			continue
		if slot.get_global_rect().has_point(global_position):
			return cell
	return null

func _get_line_from_slot_position(local_position: Vector2, cell: Vector2i) -> Dictionary:
	var left_distance = local_position.x
	var right_distance = cell_size.x - local_position.x
	var top_distance = local_position.y
	var bottom_distance = cell_size.y - local_position.y
	var horizontal_edge_distance = min(left_distance, right_distance)
	var vertical_edge_distance = min(top_distance, bottom_distance)
	if horizontal_edge_distance <= vertical_edge_distance:
		return {"type": "row", "index": cell.y}
	return {"type": "column", "index": cell.x}

func _set_hover_line(line_type: String, line_index: int) -> void:
	_hover_line_type = line_type
	_hover_line_index = line_index
	_refresh_grid_visuals()

func _refresh_grid_visuals() -> void:
	for cell in _slot_by_cell.keys():
		var slot = _slot_by_cell[cell]
		if slot == null:
			continue
		var fill = active_cell_color
		if _exhausted_cells.has(cell):
			fill = exhausted_cell_color
		elif _drag_path.has(cell):
			fill = highlight_cell_color
		elif _pending_reroll_resolution and _pending_reroll_cells.has(cell):
			fill = reroll_target_cell_color
		elif _hover_line_type == "row" and cell.y == _hover_line_index:
			fill = highlight_cell_color
		elif _hover_line_type == "column" and cell.x == _hover_line_index:
			fill = highlight_cell_color
		_apply_slot_fill(slot, fill)
	_refresh_drag_path_line()

func _apply_slot_fill(slot: PanelContainer, fill_color: Color) -> void:
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

func _begin_drag_path(cell: Vector2i, slot: PanelContainer) -> void:
	if slot == null:
		_log_trace_debug("begin_rejected cell=%s reason=no_slot" % str(cell))
		return
	_dragging_path = true
	_drag_path = [cell]
	_log_trace_debug("begin_ok cell=%s state=%s" % [str(cell), _get_cell_trace_state(cell)])
	reveal_hint_label.text = "Traccia una sequenza ortogonale di 2 fino a %d caselle. Contano solo le icone ancora attive." % current_max_trace_length
	_refresh_grid_visuals()

func _extend_drag_path(cell: Vector2i) -> void:
	if not _dragging_path:
		_log_trace_debug("extend_rejected cell=%s reason=not_dragging" % str(cell))
		return
	if _drag_path.is_empty():
		_drag_path = [cell]
		_log_trace_debug("extend_seed cell=%s" % str(cell))
		return
	var last_cell = _drag_path[_drag_path.size() - 1]
	if cell == last_cell:
		_log_trace_debug("extend_ignored cell=%s reason=same_cell" % str(cell))
		return
	if _drag_path.has(cell):
		_log_trace_debug("extend_ignored cell=%s reason=already_in_path" % str(cell))
		return
	if _drag_path.size() >= current_max_trace_length:
		_log_trace_debug("extend_rejected cell=%s reason=max_length path=%s" % [str(cell), str(_drag_path)])
		return
	if not _are_cells_orthogonally_adjacent(last_cell, cell):
		_log_trace_debug("extend_rejected cell=%s reason=not_adjacent last=%s" % [str(cell), str(last_cell)])
		return
	var slot = _slot_by_cell.get(cell, null) as PanelContainer
	if slot == null:
		_log_trace_debug("extend_rejected cell=%s reason=no_slot" % str(cell))
		return
	_drag_path.append(cell)
	_log_trace_debug("extend_ok cell=%s state=%s path=%s" % [str(cell), _get_cell_trace_state(cell), str(_drag_path)])
	_refresh_grid_visuals()

func _finalize_drag_path() -> void:
	if not _dragging_path:
		_log_trace_debug("finalize_ignored reason=not_dragging")
		return
	_dragging_path = false
	var final_path = _drag_path.duplicate()
	_drag_path.clear()
	_refresh_drag_path_line()
	if final_path.size() < 2 or final_path.size() > current_max_trace_length:
		_log_trace_debug("finalize_invalid path=%s size=%d" % [str(final_path), final_path.size()])
		reveal_hint_label.text = "La traccia deve usare da 2 a %d caselle ortogonali." % current_max_trace_length
		_refresh_grid_visuals()
		return
	_log_trace_debug("finalize_ok path=%s" % str(final_path))
	_resolve_path_selection(final_path, true)

func _ensure_drag_path_lines() -> void:
	if grid_layer == null:
		return
	if _drag_path_overlay == null:
		_drag_path_overlay = Control.new()
		_drag_path_overlay.name = "DragPathOverlay"
		_drag_path_overlay.set_script(DRAG_PATH_OVERLAY_SCRIPT)
		_drag_path_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drag_path_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_drag_path_overlay.custom_minimum_size = grid_layer.custom_minimum_size
		_drag_path_overlay.size = grid_layer.size
		_drag_path_overlay.z_index = 50
		grid_layer.add_child(_drag_path_overlay)
	else:
		_drag_path_overlay.custom_minimum_size = grid_layer.custom_minimum_size
		_drag_path_overlay.size = grid_layer.size
	_refresh_drag_path_line()

func _refresh_drag_path_line() -> void:
	if _drag_path_overlay == null:
		return
	if _drag_path.size() < 2:
		_drag_path_overlay.visible = false
		if _drag_path_overlay.has_method("set_path_points"):
			_drag_path_overlay.call("set_path_points", PackedVector2Array())
		return
	var points: PackedVector2Array = PackedVector2Array()
	for cell in _drag_path:
		var point = _get_cell_center_in_grid(cell)
		if point == null:
			continue
		points.append(point)
	_drag_path_overlay.visible = points.size() >= 2
	if _drag_path_overlay.has_method("set_path_points"):
		_drag_path_overlay.call("set_path_points", points)

func _get_cell_center_in_grid(cell: Vector2i):
	var slot = _slot_by_cell.get(cell, null) as Control
	if slot == null:
		return null
	var slot_rect = slot.get_global_rect()
	var layer_rect = grid_layer.get_global_rect()
	return slot_rect.position + slot_rect.size * 0.5 - layer_rect.position

func _are_cells_orthogonally_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta = a - b
	return abs(delta.x) + abs(delta.y) == 1

func _resolve_path_selection(path: Array, finish_action: bool) -> void:
	if path.is_empty():
		_log_trace_debug("resolve_ignored reason=empty_path")
		return
	var used_symbol_entries: Array = []
	for raw_cell in path:
		var cell: Vector2i = raw_cell
		var slot = _slot_by_cell.get(cell, null) as PanelContainer
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token") as Control
			if token != null:
				var entry = _consume_token_use(cell, token)
				if not entry.is_empty():
					used_symbol_entries.append(entry)
	var resolved_outputs = _resolve_formula_outputs(used_symbol_entries)
	_log_trace_debug("resolve path=%s entries=%s outputs=%s" % [str(path), str(used_symbol_entries), str(resolved_outputs)])
	_apply_resolved_outputs(resolved_outputs)
	var summary = _summarize_outputs(resolved_outputs)
	if not finish_action and not summary.is_empty():
		reveal_hint_label.text = _compose_status_text("Formula risolta: %s" % summary)
	elif not finish_action:
		reveal_hint_label.text = _compose_status_text("")
	_set_hover_line("", -1)
	_refresh_grid_visuals()
	_refresh_token_cost_states()
	if finish_action:
		_end_player_action()

func _get_token_debug_symbol(token: Control) -> String:
	if token == null or not token.has_method("get_result_data"):
		return "?"
	var token_data = token.call("get_result_data") as Dictionary
	return str(token_data.get("symbol_id", token_data.get("label", "?")))

func _get_cell_trace_state(cell: Vector2i) -> String:
	var slot = _slot_by_cell.get(cell, null) as PanelContainer
	if slot == null:
		return "no_slot"
	if not slot.has_method("has_token") or not slot.call("has_token"):
		return "empty"
	var token = slot.call("get_token") as Control
	if token == null:
		return "empty"
	if _token_can_be_used(token):
		return "active:%s" % _get_token_debug_symbol(token)
	return "inactive:%s" % _get_token_debug_symbol(token)

func _count_board_tokens() -> int:
	var count := 0
	for slot in _slot_by_cell.values():
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
			count += 1
	return count

func _reset_trace_debug_log() -> void:
	var absolute_path = ProjectSettings.globalize_path(TRACE_DEBUG_LOG_PATH)
	var file = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("=== TRACE DEBUG START %s ===" % Time.get_datetime_string_from_system())
	file.store_line("absolute_path=%s" % absolute_path)

func _log_trace_debug(message: String) -> void:
	var absolute_path = ProjectSettings.globalize_path(TRACE_DEBUG_LOG_PATH)
	var file = FileAccess.open(absolute_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line("[%s] %s" % [Time.get_time_string_from_system(), message])

func _commit_line_selection(line_type: String, line_index: int) -> void:
	_resolve_line_selection(line_type, line_index, true)

func _resolve_line_selection(line_type: String, line_index: int, finish_action: bool) -> void:
	if line_type.is_empty():
		return
	var line_cells: Array[Vector2i] = []
	for cell in _slot_by_cell.keys():
		if line_type == "row" and cell.y == line_index:
			line_cells.append(cell)
		elif line_type == "column" and cell.x == line_index:
			line_cells.append(cell)
	if line_cells.is_empty():
		return
	line_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if line_type == "row":
			return a.x < b.x
		return a.y < b.y
	)
	if line_cells.size() > 4:
		line_cells = line_cells.slice(0, 4)
	_resolve_path_selection(line_cells, finish_action)

func _request_line_reroll(line_type: String, line_index: int) -> void:
	reveal_hint_label.text = "Il rilancio non fa piu parte di questo sistema."

func _on_rest_button_pressed() -> void:
	if not enemy_revealed:
		return
	if _exhausted_cells.is_empty():
		reveal_hint_label.text = "Non ci sono dadi esausti da ricaricare."
		return
	_restore_exhausted_dice()
	_end_player_action()

func _on_ability_button_pressed() -> void:
	if not enemy_revealed:
		return
	if _pending_reroll_resolution:
		reveal_hint_label.text = "Prima completa il riposizionamento dei dadi rilanciati."
		return
	if current_character_ability_effects.is_empty():
		reveal_hint_label.text = "Questo personaggio non ha un'abilita disponibile."
		return
	var hp_cost = _get_ability_hp_cost()
	if hp_cost > 0 and current_character_hp <= hp_cost:
		reveal_hint_label.text = "Non hai abbastanza punti vita per usare l'abilita."
		return
	if not _apply_character_ability():
		return
	if hp_cost > 0:
		current_character_hp -= hp_cost
		character_hp_changed.emit(current_character_hp)
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)
	_end_player_action()

func _on_flee_button_pressed() -> void:
	if not enemy_revealed:
		return
	if _pending_reroll_resolution:
		reveal_hint_label.text = "Prima completa il riposizionamento dei dadi rilanciati."
		return
	var flee_text = str(current_enemy.get("flee_text", "")).strip_edges()
	_apply_flee_effects()
	var next_hint = "Hai usato Fuga. Nuova carta pronta da scoprire."
	if not flee_text.is_empty():
		next_hint = "Hai usato Fuga: %s. Nuova carta pronta da scoprire." % flee_text
	_prepare_hidden_enemy(next_hint)

func _consume_enemy_requirements(used_symbol_entries: Array) -> void:
	for entry in used_symbol_entries:
		if not (entry is Dictionary):
			continue
		var symbol_id = str(entry.get("symbol_id", ""))
		var amount = int(entry.get("value", 1))
		if symbol_id.is_empty():
			symbol_id = _infer_symbol_id_from_label(str(entry.get("label", "")))
		var total_consumption = amount
		if symbol_id == current_weapon_attack_symbol:
			total_consumption = amount * max(1, current_weapon_damage_per_hit)
		if symbol_id == "spada":
			var blocked_consumption = min(current_enemy_blocks, total_consumption)
			current_enemy_blocks -= blocked_consumption
			total_consumption -= blocked_consumption
		for _i in range(total_consumption):
			var requirement_index = current_enemy_requirements.find(symbol_id)
			if requirement_index >= 0:
				current_enemy_requirements.remove_at(requirement_index)
	_build_requirements_row()
	damage_line_label.text = _get_enemy_meta_text(int(current_enemy.get("enemy_damage", 0)))
	_update_ability_label()

func _collect_gold_from_symbols(used_symbol_entries: Array) -> void:
	var gained_gold := 0
	for entry in used_symbol_entries:
		if not (entry is Dictionary):
			continue
		var symbol_id = str(entry.get("symbol_id", ""))
		if symbol_id.is_empty():
			symbol_id = _infer_symbol_id_from_label(str(entry.get("label", "")))
		if symbol_id != "moneta":
			continue
		gained_gold += int(entry.get("value", 1))
	if gained_gold <= 0:
		return
	current_gold += gained_gold
	_update_ability_label()
	_refresh_token_cost_states()
	player_stats_changed.emit(current_character_hp, current_gold)

func _collect_healing_from_symbols(used_symbol_entries: Array) -> void:
	var gained_hp := 0
	for entry in used_symbol_entries:
		if not (entry is Dictionary):
			continue
		var symbol_id = str(entry.get("symbol_id", ""))
		if symbol_id.is_empty():
			symbol_id = _infer_symbol_id_from_label(str(entry.get("label", "")))
		if symbol_id != "cuore":
			continue
		gained_hp += int(entry.get("value", 1))
	if gained_hp <= 0:
		return
	current_character_hp += gained_hp
	character_hp_changed.emit(current_character_hp)
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)

func _apply_flee_effects() -> void:
	var flee_effects = current_enemy.get("flee_effects", [])
	if not (flee_effects is Array):
		return
	for effect in flee_effects:
		if not (effect is Dictionary):
			continue
		var effect_type = str(effect.get("type", ""))
		if effect_type == "lose_hp":
			var amount = int(effect.get("amount", 0))
			if amount > 0:
				current_character_hp = max(current_character_hp - amount, 0)
		elif effect_type == "disable_random_die_for_turns":
			_disable_random_active_die()
		elif effect_type == "remove_symbol_from_die":
			_remove_random_active_symbol()
	character_hp_changed.emit(current_character_hp)
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)

func _apply_reward_effects() -> void:
	var reward_effects = current_enemy.get("reward_effects", [])
	if not (reward_effects is Array):
		return
	var resources_changed := false
	for effect in reward_effects:
		if not (effect is Dictionary):
			continue
		var effect_type = str(effect.get("type", ""))
		var amount = max(0, int(effect.get("amount", 0)))
		match effect_type:
			"gain_coins":
				if amount > 0:
					current_gold += amount
					resources_changed = true
			"gain_arrows":
				if amount > 0:
					current_arrows += amount
					resources_changed = true
	if resources_changed:
		_update_ability_label()
		_refresh_token_cost_states()
		player_stats_changed.emit(current_character_hp, current_gold)

func _disable_random_active_die() -> void:
	var available_cells: Array = []
	for cell in _slot_by_cell.keys():
		if _exhausted_cells.has(cell):
			continue
		var slot = _slot_by_cell[cell] as PanelContainer
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token") as Control
			if token != null and _token_is_exhaustible(token):
				available_cells.append(cell)
	if available_cells.is_empty():
		return
	var chosen_cell = available_cells[randi() % available_cells.size()]
	if not _exhausted_cells.has(chosen_cell):
		_exhausted_cells.append(chosen_cell)
	var chosen_slot = _slot_by_cell[chosen_cell] as PanelContainer
	if chosen_slot != null and chosen_slot.has_method("has_token") and chosen_slot.call("has_token"):
		var token = chosen_slot.call("get_token") as Control
		if token != null and token.has_method("set_exhausted"):
			token.call("set_exhausted", true)
	_refresh_grid_visuals()

func _remove_random_active_symbol() -> void:
	var available_cells: Array = []
	for cell in _slot_by_cell.keys():
		var slot = _slot_by_cell[cell] as PanelContainer
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
			available_cells.append(cell)
	if available_cells.is_empty():
		return
	var chosen_cell = available_cells[randi() % available_cells.size()]
	var chosen_slot = _slot_by_cell[chosen_cell] as PanelContainer
	if chosen_slot != null and chosen_slot.has_method("clear_token"):
		var token = chosen_slot.call("clear_token") as Control
		if token != null:
			token.queue_free()

func _restore_exhausted_dice() -> void:
	_exhausted_cells.clear()
	for slot in _slot_by_cell.values():
		if slot == null:
			continue
		if slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token") as Control
			if token != null and token.has_method("set_exhausted") and _token_is_exhaustible(token):
				token.call("set_exhausted", false)
	_set_hover_line("", -1)
	_refresh_grid_visuals()

func _handle_enemy_defeated() -> void:
	var equip_text := ""
	if str(current_enemy.get("category", "")) == "object":
		equip_text = _equip_current_object()
	_apply_reward_effects()
	var reward_text = str(current_enemy.get("reward_text", "")).strip_edges()
	var next_hint = "Nemico sconfitto. Nuova carta pronta da scoprire."
	if not equip_text.is_empty():
		next_hint = equip_text
	if not reward_text.is_empty():
		next_hint = "%s Premio: %s." % [next_hint, reward_text]
	next_hint = _compose_status_text(next_hint)
	if not next_hint.ends_with("Nuova carta pronta da scoprire."):
		next_hint = "%s Nuova carta pronta da scoprire." % next_hint
	_restore_exhausted_dice()
	_prepare_hidden_enemy(next_hint)

func _enemy_survived_player_action() -> bool:
	return enemy_revealed and not current_enemy_requirements.is_empty()

func _infer_symbol_id_from_label(label: String) -> String:
	var lower = label.to_lower()
	if lower.contains("spad"):
		return "spada"
	if lower.contains("scud"):
		return "scudo"
	if lower.contains("cuor"):
		return "cuore"
	if lower.contains("monet"):
		return "moneta"
	if lower.contains("magi"):
		return "magia"
	if lower.contains("ladr"):
		return "ladro"
	if lower.contains("arc"):
		return "arco"
	return lower

func _all_pending_reroll_cells_filled() -> bool:
	if _pending_reroll_cells.is_empty():
		return false
	for cell in _pending_reroll_cells:
		var slot = _slot_by_cell.get(cell, null) as PanelContainer
		if slot == null:
			return false
		if not slot.has_method("has_token") or not slot.call("has_token"):
			return false
	return true

func notify_token_placed(_slot: PanelContainer) -> void:
	if not _pending_reroll_resolution:
		if _all_results_placed():
			_board_layout_locked = true
			_refresh_board_token_drag_state()
		return
	if not _all_results_placed():
		return
	if not _all_pending_reroll_cells_filled():
		return
	_pending_reroll_resolution = false
	_pending_reroll_cells.clear()
	_board_layout_locked = true
	_refresh_board_token_drag_state()
	_refresh_grid_visuals()
	reveal_hint_label.text = "Rilancio confermato."
	_end_player_action()

func _refresh_board_token_drag_state() -> void:
	var disable_drag := enemy_revealed or _board_layout_locked
	_set_board_tokens_interaction(disable_drag)

func _set_board_tokens_interaction(enabled: bool) -> void:
	for slot in _slot_by_cell.values():
		if slot == null or not slot.has_method("has_token") or not slot.call("has_token"):
			continue
		var token = slot.call("get_token") as Control
		if token != null and token.has_method("set_board_interaction_enabled"):
			token.call("set_board_interaction_enabled", enabled)

func _end_player_action() -> void:
	if not _enemy_survived_player_action():
		_handle_enemy_defeated()
		return
	var attack_result = _choose_enemy_attack_result()
	var attack_count = int(attack_result.get("attack_count", 0))
	var block_count = int(attack_result.get("block_count", 0))
	var heal_count = int(attack_result.get("heal_count", 0))
	var sequence_summary = str(attack_result.get("summary", ""))
	_current_enemy_sequence_summary = sequence_summary
	var blocked_attacks = min(current_pending_defense, attack_count)
	var unblocked_attacks = max(attack_count - blocked_attacks, 0)
	var damage_per_attack = max(1, int(current_enemy.get("enemy_damage", 1)))
	var incoming_damage = max((unblocked_attacks * damage_per_attack) - current_armor, 0)
	current_enemy_blocks += block_count
	var restored_requirements = _heal_enemy_requirements(heal_count)
	damage_line_label.text = _get_enemy_meta_text(damage_per_attack)
	current_pending_defense = 0
	current_character_hp = max(current_character_hp - incoming_damage, 0)
	character_hp_changed.emit(current_character_hp)
	_update_ability_label()
	_refresh_token_cost_states()
	player_stats_changed.emit(current_character_hp, current_gold)
	var sequence_text = ""
	if not sequence_summary.is_empty():
		sequence_text = " Sequenza: %s." % sequence_summary
	if block_count > 0:
		sequence_text += " Il nemico prepara %d parate per il prossimo turno." % block_count
	if restored_requirements > 0:
		sequence_text += " Il nemico recupera %d punti vita." % restored_requirements
	if incoming_damage > 0:
		reveal_hint_label.text = _compose_status_text("Il nemico colpisce per %d danni.%s Ora tocca di nuovo a te." % [incoming_damage, sequence_text])
	else:
		reveal_hint_label.text = _compose_status_text("Hai bloccato o assorbito l'attacco.%s Ora tocca di nuovo a te." % sequence_text)

func _choose_enemy_attack_result() -> Dictionary:
	var sequences = current_enemy.get("attack_sequences", [])
	if not (sequences is Array) or sequences.is_empty():
		var legacy_damage = max(0, int(current_enemy.get("enemy_damage", 1)))
		return {
			"attack_count": 1 if legacy_damage > 0 else 0,
			"block_count": 0,
			"summary": ""
		}
	var normalized_sequences = _normalize_enemy_attack_sequences(sequences)
	if normalized_sequences.is_empty():
		return {"attack_count": 0, "block_count": 0, "summary": ""}
	var sequence = normalized_sequences[randi() % normalized_sequences.size()]
	var attack_count := 0
	var block_count := 0
	var heal_count := 0
	for token in sequence:
		match str(token):
			"spada":
				attack_count += 1
			"scudo":
				block_count += 1
			"cuore":
				heal_count += 1
	return {
		"attack_count": attack_count,
		"block_count": block_count,
		"heal_count": heal_count,
		"summary": _summarize_enemy_attack_sequence(sequence)
	}

func _normalize_enemy_attack_sequences(raw_sequences) -> Array:
	var sequences: Array = []
	if not (raw_sequences is Array):
		return sequences
	for raw_sequence in raw_sequences:
		var sequence: Array = []
		if raw_sequence is Array:
			for raw_token in raw_sequence:
				var token = str(raw_token).strip_edges().to_lower()
				if token == "attacco" or token == "attacca":
					token = "spada"
				elif token == "para" or token == "parata" or token == "blocco":
					token = "scudo"
				if ENEMY_ICON_PATHS.has(token):
					sequence.append(token)
		if not sequence.is_empty():
			sequences.append(sequence)
	return sequences

func _summarize_enemy_attack_sequence(sequence: Array) -> String:
	var parts: Array[String] = []
	for token in sequence:
		match str(token):
			"spada":
				parts.append("attacco")
			"scudo":
				parts.append("para")
			"cuore":
				parts.append("cura")
			_:
				parts.append(str(token))
	return ", ".join(parts)

func _heal_enemy_requirements(heal_amount: int) -> int:
	if heal_amount <= 0:
		return 0
	var base_requirements = current_enemy.get("requirements", [])
	if not (base_requirements is Array) or base_requirements.is_empty():
		return 0
	var restored := 0
	for requirement in base_requirements:
		if restored >= heal_amount:
			break
		var requirement_id = str(requirement)
		var current_count = current_enemy_requirements.count(requirement_id)
		var max_count = base_requirements.count(requirement_id)
		if current_count >= max_count:
			continue
		current_enemy_requirements.append(requirement_id)
		restored += 1
	if restored > 0:
		_build_requirements_row()
		damage_line_label.text = _get_enemy_meta_text(int(current_enemy.get("enemy_damage", 0)))
	return restored

func _update_ability_label() -> void:
	var enemy_block_text = ""
	if current_enemy_blocks > 0:
		enemy_block_text = " | Parate Nemico: %d" % current_enemy_blocks
	ability_label.text = "%s | PV: %d | PM: %d | Oro: %d | Frecce: %d | Difesa: %d | Danno %s: %d | Armatura: %d%s | Abilita: %s" % [current_character_name, current_character_hp, current_character_mp, current_gold, current_arrows, current_pending_defense, _get_icon_display_name(current_weapon_attack_symbol), current_weapon_damage_per_hit, current_armor, enemy_block_text, current_character_ability]

func _get_ability_hp_cost() -> int:
	for effect in current_character_ability_effects:
		if effect is Dictionary and str(effect.get("type", "")) == "pay_hp_cost":
			return int(effect.get("amount", 0))
	return 0

func _apply_character_ability() -> bool:
	var applied = false
	for effect in current_character_ability_effects:
		if not (effect is Dictionary):
			continue
		var effect_type = str(effect.get("type", ""))
		match effect_type:
			"reactivate_exhausted_die":
				applied = _ability_reactivate_exhausted_die()
			"create_ephemeral_symbol":
				applied = _ability_create_ephemeral_symbol()
			"set_exhausted_die_symbol":
				applied = _ability_set_exhausted_die_symbol()
			"select_extra_line":
				applied = _ability_select_extra_line()
			"pay_hp_cost":
				continue
		if applied:
			return true
	reveal_hint_label.text = "L'abilita non puo essere usata in questo momento."
	return false

func _ability_reactivate_exhausted_die() -> bool:
	if _exhausted_cells.is_empty():
		reveal_hint_label.text = "Non ci sono dadi esausti da riattivare."
		return false
	var chosen_cell = _exhausted_cells[0]
	_exhausted_cells.erase(chosen_cell)
	var slot = _slot_by_cell.get(chosen_cell, null) as PanelContainer
	if slot != null and slot.has_method("has_token") and slot.call("has_token"):
		var token = slot.call("get_token") as Control
		if token != null and token.has_method("set_exhausted"):
			token.call("set_exhausted", false)
	_refresh_grid_visuals()
	reveal_hint_label.text = "Abilita usata: un dado esausto e stato riattivato."
	return true

func _ability_create_ephemeral_symbol() -> bool:
	var symbol_id = _get_priority_symbol_for_ability()
	var token_data = _create_symbol_result_data(symbol_id)
	if token_data.is_empty():
		return false
	token_data["durability_mode"] = "ephemeral"
	token_data["remaining_uses"] = int(token_data.get("value", 1))
	var tray_slot := _create_drop_slot(tray_slot_color)
	tray_slot.custom_minimum_size = Vector2(96, 96)
	tray_slot.set_meta("remove_when_empty", true)
	token_tray.add_child(tray_slot)
	var token := TextureRect.new()
	token.set_script(RESULT_TOKEN_SCRIPT)
	token.call("setup", token_data)
	tray_slot.call("place_token", token)
	reveal_hint_label.text = "Abilita usata: simbolo effimero creato."
	return true

func _ability_set_exhausted_die_symbol() -> bool:
	if _exhausted_cells.is_empty():
		reveal_hint_label.text = "Non ci sono dadi esausti da modificare."
		return false
	var chosen_cell = _exhausted_cells[0]
	var slot = _slot_by_cell.get(chosen_cell, null) as PanelContainer
	if slot == null or not slot.has_method("has_token") or not slot.call("has_token"):
		reveal_hint_label.text = "Il dado esausto selezionato non e disponibile."
		return false
	var token = slot.call("get_token") as Control
	if token == null or not token.has_method("set_result_data_value"):
		return false
	var symbol_id = _get_priority_symbol_for_ability()
	var token_data = _create_symbol_result_data(symbol_id)
	if token_data.is_empty():
		return false
	for key in token_data.keys():
		token.call("set_result_data_value", str(key), token_data[key])
	if token.has_method("set_exhausted"):
		token.call("set_exhausted", true)
	reveal_hint_label.text = "Abilita usata: un dado esausto e stato impostato su %s." % str(token_data.get("label", ""))
	return true

func _ability_select_extra_line() -> bool:
	var best_path = _find_best_drag_path()
	if best_path.is_empty():
		reveal_hint_label.text = "Non ci sono altre sequenze utilizzabili."
		return false
	_resolve_path_selection(best_path, false)
	reveal_hint_label.text = "Abilita usata: hai risolto una sequenza aggiuntiva."
	return true

func _get_priority_symbol_for_ability() -> String:
	if not current_enemy_requirements.is_empty():
		return str(current_enemy_requirements[0])
	return "spada"

func _create_symbol_result_data(symbol_id: String) -> Dictionary:
	var icon_path = str(ENEMY_ICON_PATHS.get(symbol_id, ""))
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return {}
	var label = "1 %s" % symbol_id
	return {
		"face_id": 0,
		"value": 1,
		"label": label,
		"base_label": label,
		"symbol_id": symbol_id,
		"symbol_texture": load(icon_path),
		"dice_type": "ability",
		"dice_name": "Ability",
		"durability_mode": "exhaustible",
		"remaining_uses": 1
	}

func _create_loadout_result_data(loadout_entry) -> Dictionary:
	var entry: Dictionary = {}
	if loadout_entry is Dictionary:
		entry = loadout_entry.duplicate(true)
	else:
		entry = {"symbol_id": str(loadout_entry)}
	var normalized_symbol = str(entry.get("symbol_id", entry.get("id", ""))).strip_edges().to_lower()
	if normalized_symbol.is_empty():
		return {}
	var label = normalized_symbol
	var value = 1
	if normalized_symbol == "x2":
		value = 2
	var durability_mode = str(entry.get("durability_mode", "exhaustible")).strip_edges().to_lower()
	if durability_mode != "ephemeral" and durability_mode != "perennial":
		durability_mode = "exhaustible"
	var remaining_uses = max(1, int(entry.get("remaining_uses", 1)))
	if durability_mode != "ephemeral":
		remaining_uses = 1
	var icon_path = str(ENEMY_ICON_PATHS.get(normalized_symbol, ""))
	var texture: Texture2D = null
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		texture = load(icon_path)
	return {
		"face_id": 0,
		"value": value,
		"label": label,
		"base_label": label,
		"symbol_id": normalized_symbol,
		"symbol_texture": texture,
		"dice_type": "loadout",
		"dice_name": "Loadout",
		"durability_mode": durability_mode,
		"remaining_uses": remaining_uses
	}

func _resolve_formula_outputs(entries: Array) -> Array:
	var outputs: Array = []
	var current_block: Dictionary = {}
	var can_merge_same_symbol := true
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var symbol_id = str(entry.get("symbol_id", "")).strip_edges().to_lower()
		if symbol_id.is_empty():
			symbol_id = _infer_symbol_id_from_label(str(entry.get("label", "")))
		var amount = int(entry.get("value", 1))
		if MODIFIER_SYMBOLS.has(symbol_id):
			if not current_block.is_empty():
				outputs.append(current_block.duplicate(true))
				current_block.clear()
			if outputs.is_empty():
				continue
			var last_output = outputs[outputs.size() - 1]
			if symbol_id == "+1":
				last_output["value"] = int(last_output.get("value", 0)) + 1
			elif symbol_id == "x2":
				last_output["value"] = int(last_output.get("value", 0)) * 2
			outputs[outputs.size() - 1] = last_output
			can_merge_same_symbol = false
			continue
		if current_block.is_empty():
			current_block = {"symbol_id": symbol_id, "value": amount}
			can_merge_same_symbol = true
			continue
		if can_merge_same_symbol and str(current_block.get("symbol_id", "")) == symbol_id:
			current_block["value"] = int(current_block.get("value", 0)) + amount
		else:
			outputs.append(current_block.duplicate(true))
			current_block = {"symbol_id": symbol_id, "value": amount}
		can_merge_same_symbol = true
	if not current_block.is_empty():
		outputs.append(current_block.duplicate(true))
	return outputs

func _apply_resolved_outputs(outputs: Array) -> void:
	current_pending_defense = 0
	var requirement_entries: Array = []
	var healing_entries: Array = []
	var gold_entries: Array = []
	for output in outputs:
		if not (output is Dictionary):
			continue
		var symbol_id = str(output.get("symbol_id", ""))
		match symbol_id:
			"scudo":
				current_pending_defense += int(output.get("value", 0))
			"cuore":
				healing_entries.append(output)
			"moneta":
				gold_entries.append(output)
			_:
				requirement_entries.append(output)
	_collect_healing_from_symbols(healing_entries)
	_collect_gold_from_symbols(gold_entries)
	_consume_enemy_requirements(requirement_entries)

func _summarize_outputs(outputs: Array) -> String:
	var parts: Array[String] = []
	for output in outputs:
		if not (output is Dictionary):
			continue
		parts.append("%s(%d)" % [str(output.get("symbol_id", "")), int(output.get("value", 0))])
	return ", ".join(parts)

func _find_best_drag_path() -> Array:
	var best_path: Array = []
	for start_cell in _slot_by_cell.keys():
		var candidate = _find_best_drag_path_from(start_cell, [], 4)
		if candidate.size() > best_path.size():
			best_path = candidate.duplicate()
	return best_path

func _find_best_drag_path_from(cell: Vector2i, path: Array, remaining_steps: int) -> Array:
	var slot = _slot_by_cell.get(cell, null) as PanelContainer
	if slot == null or not slot.has_method("has_token") or not slot.call("has_token"):
		return path
	var token = slot.call("get_token") as Control
	if token == null or not _token_can_be_used(token):
		return path
	var current_path = path.duplicate()
	if current_path.has(cell):
		return current_path
	current_path.append(cell)
	if remaining_steps <= 1:
		return current_path
	var best_path = current_path.duplicate()
	for neighbor in _get_adjacent_cells(cell):
		if current_path.has(neighbor):
			continue
		var candidate = _find_best_drag_path_from(neighbor, current_path, remaining_steps - 1)
		if candidate.size() > best_path.size():
			best_path = candidate
	return best_path

func _get_adjacent_cells(cell: Vector2i) -> Array:
	return [
		Vector2i(cell.x + 1, cell.y),
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x, cell.y + 1),
		Vector2i(cell.x, cell.y - 1)
	]

func _count_active_tokens_in_line(line_type: String, line_index: int) -> int:
	var count := 0
	for cell in _slot_by_cell.keys():
		if _exhausted_cells.has(cell):
			continue
		if line_type == "row" and cell.y != line_index:
			continue
		if line_type == "column" and cell.x != line_index:
			continue
		var slot = _slot_by_cell[cell] as PanelContainer
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token") as Control
			if token != null and _token_can_be_used(token):
				count += 1
	return count

func _consume_token_use(cell: Vector2i, token: Control) -> Dictionary:
	if token == null or not _token_can_be_used(token):
		return {}
	var token_data: Dictionary = {}
	if token.has_method("get_result_data"):
		token_data = token.call("get_result_data") as Dictionary
	if not _pay_token_activation_cost(token_data):
		_refresh_token_cost_states()
		return {}
	if not token.has_method("consume_use"):
		if _token_is_exhaustible(token) and not _exhausted_cells.has(cell):
			_exhausted_cells.append(cell)
		if token.has_method("set_exhausted"):
			token.call("set_exhausted", true)
		if token.has_method("get_result_data"):
			return token.call("get_result_data")
		return {}
	var used_entry = token.call("consume_use") as Dictionary
	if _token_is_exhaustible(token) and not _exhausted_cells.has(cell):
		_exhausted_cells.append(cell)
	if token.has_method("should_be_removed_after_use") and bool(token.call("should_be_removed_after_use")):
		var removed_token_data = used_entry.duplicate(true)
		var slot = _slot_by_cell.get(cell, null) as PanelContainer
		if slot != null and slot.has_method("clear_token"):
			var removed = slot.call("clear_token") as Control
			if removed != null:
				removed.queue_free()
		_handle_destroyed_object_token(removed_token_data)
	_refresh_token_cost_states()
	return used_entry

func _normalize_result_data(result: Dictionary) -> Dictionary:
	var normalized = result.duplicate(true)
	if not normalized.has("durability_mode"):
		normalized["durability_mode"] = "exhaustible"
	if not normalized.has("base_label"):
		normalized["base_label"] = str(normalized.get("label", ""))
	if not normalized.has("remaining_uses"):
		normalized["remaining_uses"] = int(normalized.get("value", 1))
	if not normalized.has("activation_cost_type"):
		normalized["activation_cost_type"] = "none"
	if not normalized.has("activation_cost_amount"):
		normalized["activation_cost_amount"] = 0
	return normalized

func _token_can_be_used(token: Control) -> bool:
	if token == null:
		return false
	if token.has_method("get_result_data"):
		var token_data = token.call("get_result_data") as Dictionary
		if not _can_pay_token_activation_cost(token_data):
			return false
	if token.has_method("can_be_used"):
		return bool(token.call("can_be_used"))
	return true

func _can_pay_token_activation_cost(token_data: Dictionary) -> bool:
	var cost_type = str(token_data.get("activation_cost_type", "none")).strip_edges().to_lower()
	var cost_amount = max(0, int(token_data.get("activation_cost_amount", 0)))
	if cost_amount <= 0 or cost_type == "none":
		return true
	if cost_type == "mana":
		return current_character_mp >= cost_amount
	if cost_type == "arrows" or cost_type == "freccia" or cost_type == "frecce":
		return current_arrows >= cost_amount
	return true

func _pay_token_activation_cost(token_data: Dictionary) -> bool:
	var cost_type = str(token_data.get("activation_cost_type", "none")).strip_edges().to_lower()
	var cost_amount = max(0, int(token_data.get("activation_cost_amount", 0)))
	if cost_amount <= 0 or cost_type == "none":
		return true
	if not _can_pay_token_activation_cost(token_data):
		return false
	if cost_type == "mana":
		current_character_mp = max(current_character_mp - cost_amount, 0)
		_update_ability_label()
	elif cost_type == "arrows" or cost_type == "freccia" or cost_type == "frecce":
		current_arrows = max(current_arrows - cost_amount, 0)
		_update_ability_label()
	return true

func _refresh_token_cost_states() -> void:
	for slot in token_tray.get_children():
		_refresh_token_cost_state_in_slot(slot)
	for slot in _slot_by_cell.values():
		_refresh_token_cost_state_in_slot(slot)

func _refresh_token_cost_state_in_slot(slot) -> void:
	if slot == null or not slot.has_method("has_token") or not slot.call("has_token"):
		return
	var token = slot.call("get_token") as Control
	if token == null or not token.has_method("get_result_data") or not token.has_method("set_disabled_by_cost"):
		return
	var token_data = token.call("get_result_data") as Dictionary
	token.call("set_disabled_by_cost", not _can_pay_token_activation_cost(token_data))

func _token_is_exhaustible(token: Control) -> bool:
	if token == null:
		return false
	if token.has_method("get_durability_mode"):
		return str(token.call("get_durability_mode")) == "exhaustible"
	return true

func _slot_token_is_rerollable(slot: PanelContainer) -> bool:
	if slot == null or not slot.has_method("has_token") or not slot.call("has_token"):
		return false
	var token = slot.call("get_token") as Control
	return token != null and _token_is_exhaustible(token)

func _get_enemy_meta_text(enemy_damage: int) -> String:
	if str(current_enemy.get("category", "")) != "object":
		var sequences = _normalize_enemy_attack_sequences(current_enemy.get("attack_sequences", []))
		if sequences.is_empty():
			return "Nessuna sequenza attacco"
		var hp_text = "PV: %d" % current_enemy_requirements.size()
		var damage_text = "Danno/colpo: %d" % max(1, enemy_damage)
		var sequence_text = "Sequenze: %d" % sequences.size()
		if not _current_enemy_sequence_summary.is_empty():
			sequence_text = "Sequenza: %s" % _current_enemy_sequence_summary
		return "%s | %s | %s" % [hp_text, damage_text, sequence_text]
	var slot_id = str(current_enemy.get("equipment_slot", "weapon"))
	var attack_bonus = int(current_enemy.get("attack_bonus", 0))
	var weapon_attack_count = int(current_enemy.get("weapon_attack_count", 0))
	var weapon_damage_per_hit = int(current_enemy.get("weapon_damage_per_hit", attack_bonus + 1 if attack_bonus > 0 else 0))
	var armor_value = int(current_enemy.get("armor_value", 0))
	if weapon_damage_per_hit > 0:
		return "Danno %d" % weapon_damage_per_hit
	if armor_value > 0:
		return "Armatura %d" % armor_value
	return ""

func _update_battle_card_header(is_object: bool) -> void:
	_ensure_object_header()
	card_name_label.visible = true
	if _object_header_container == null:
		return
	_object_header_container.visible = false

func _ensure_object_header() -> void:
	if _object_header_container != null or preview_card == null:
		return
	_object_header_container = VBoxContainer.new()
	_object_header_container.layout_mode = 1
	_object_header_container.offset_left = 24.0
	_object_header_container.offset_top = 16.0
	_object_header_container.offset_right = 356.0
	_object_header_container.offset_bottom = 180.0
	_object_header_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_object_header_container.add_theme_constant_override("separation", 6)
	preview_card.add_child(_object_header_container)
	preview_card.move_child(_object_header_container, preview_card.get_child_count() - 1)
	_object_header_label = Label.new()
	_object_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_object_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_object_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_object_header_label.add_theme_font_size_override("font_size", 28)
	_object_header_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_object_header_label.add_theme_constant_override("outline_size", 4)
	_object_header_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_object_header_container.add_child(_object_header_label)
	_object_header_icon_holder = Control.new()
	_object_header_icon_holder.custom_minimum_size = Vector2(96, 96)
	_object_header_container.add_child(_object_header_icon_holder)
	_object_header_background = TextureRect.new()
	_object_header_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_object_header_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_object_header_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_object_header_icon_holder.add_child(_object_header_background)
	_object_header_icon = TextureRect.new()
	_object_header_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_object_header_icon.offset_left = 10.0
	_object_header_icon.offset_top = 10.0
	_object_header_icon.offset_right = -10.0
	_object_header_icon.offset_bottom = -10.0
	_object_header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_object_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_object_header_icon_holder.add_child(_object_header_icon)
	_object_header_charges_label = Label.new()
	_object_header_charges_label.layout_mode = 1
	_object_header_charges_label.offset_left = 26.0
	_object_header_charges_label.offset_top = -16.0
	_object_header_charges_label.offset_right = 70.0
	_object_header_charges_label.offset_bottom = 14.0
	_object_header_charges_label.add_theme_font_size_override("font_size", 22)
	_object_header_charges_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_object_header_charges_label.add_theme_constant_override("outline_size", 3)
	_object_header_charges_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_object_header_charges_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_object_header_charges_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_object_header_icon_holder.add_child(_object_header_charges_label)
	_object_header_container.visible = false

func _get_current_object_header_icon_path() -> String:
	var granted_icons = current_enemy.get("granted_icons", current_enemy.get("requirements", []))
	if granted_icons is Array and not granted_icons.is_empty():
		return str(ENEMY_ICON_PATHS.get(str(granted_icons[0]), ""))
	return ""

func _get_current_object_header_background_texture() -> Texture2D:
	var durability_mode = str(current_enemy.get("granted_durability_mode", "exhaustible")).strip_edges().to_lower()
	var background_path = str(DURABILITY_BACKGROUND_PATHS.get(durability_mode, ""))
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return null
	return load(background_path)

func _build_object_granted_icons_row() -> void:
	_clear_requirements_row()
	var granted_icons = current_enemy.get("granted_icons", current_enemy.get("requirements", []))
	if not (granted_icons is Array):
		return
	var durability_mode = str(current_enemy.get("granted_durability_mode", "exhaustible")).strip_edges().to_lower()
	var charges = max(1, int(current_enemy.get("granted_remaining_uses", 1))) if durability_mode == "ephemeral" else 0
	for raw_icon in granted_icons:
		var icon = _build_card_info_icon(str(raw_icon), durability_mode, charges)
		requirements_row.add_child(icon)

func _build_card_info_icon(icon_id: String, background_mode: String = "", charges: int = 0) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(96, 96)
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var background_path = str(DURABILITY_BACKGROUND_PATHS.get(background_mode, ""))
	if not background_path.is_empty() and ResourceLoader.exists(background_path):
		background.texture = load(background_path)
	holder.add_child(background)
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 12.0
	icon.offset_top = 12.0
	icon.offset_right = -12.0
	icon.offset_bottom = -12.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path = str(ENEMY_ICON_PATHS.get(icon_id, ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	holder.add_child(icon)
	if charges > 0:
		var charges_label := Label.new()
		charges_label.layout_mode = 1
		charges_label.offset_left = 28.0
		charges_label.offset_top = -22.0
		charges_label.offset_right = 68.0
		charges_label.offset_bottom = 8.0
		charges_label.add_theme_font_size_override("font_size", 24)
		charges_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		charges_label.add_theme_constant_override("outline_size", 3)
		charges_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		charges_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		charges_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		charges_label.text = str(charges)
		holder.add_child(charges_label)
	return holder

func _update_battle_object_header_charges() -> void:
	if _object_header_charges_label == null:
		return
	var slot_id = _normalize_equipment_slot(str(current_enemy.get("equipment_slot", "weapon")))
	var durability_mode = str(current_enemy.get("granted_durability_mode", "exhaustible")).strip_edges().to_lower()
	var show_charges = slot_id == "weapon" and durability_mode == "ephemeral"
	_object_header_charges_label.visible = show_charges
	if show_charges:
		_object_header_charges_label.text = str(max(1, int(current_enemy.get("granted_remaining_uses", 1))))

func _get_icon_display_name(icon_id: String) -> String:
	match icon_id.strip_edges().to_lower():
		"spada":
			return "Spada"
		"scudo":
			return "Scudo"
		"cuore":
			return "Cura"
		"moneta":
			return "Moneta"
		"magia":
			return "Magia"
		"ladro":
			return "Ladro"
		"arco":
			return "Arco"
		"chiave":
			return "Chiave"
		"corona":
			return "Corona"
		"cristallo":
			return "Cristallo"
		"monete":
			return "Monete"
		"pergamena":
			return "Pergamena"
		"pozione":
			return "Pozione"
		"teschio":
			return "Teschio"
		"torcia":
			return "Torcia"
		_:
			return icon_id.capitalize()

func _equip_current_object() -> String:
	var slot_id = _normalize_equipment_slot(str(current_enemy.get("equipment_slot", "weapon")))
	var object_data = current_enemy.duplicate(true)
	_remove_existing_equipment_tokens(slot_id)
	current_equipment[slot_id] = object_data
	_add_object_granted_tokens(object_data)
	_recalculate_equipment_stats()
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)
	return "Oggetto equipaggiato: %s (%s)." % [str(current_enemy.get("name", "Oggetto")), _get_equipment_slot_label(slot_id)]

func _recalculate_equipment_stats() -> void:
	current_attack_bonus = 0
	current_weapon_damage_per_hit = 1
	current_weapon_attack_symbol = "spada"
	current_armor = 0
	for slot_id in current_equipment.keys():
		var item = current_equipment[slot_id]
		if item is Dictionary:
			var legacy_attack_bonus = int(item.get("attack_bonus", 0))
			var weapon_damage = int(item.get("weapon_damage_per_hit", legacy_attack_bonus + 1 if legacy_attack_bonus > 0 else 0))
			if _normalize_equipment_slot(str(item.get("equipment_slot", slot_id))) == "weapon" and weapon_damage > 0:
				current_weapon_damage_per_hit = max(current_weapon_damage_per_hit, weapon_damage)
				current_attack_bonus = max(current_attack_bonus, weapon_damage - 1)
				current_weapon_attack_symbol = _get_weapon_attack_symbol(item)
			current_armor += int(item.get("armor_value", 0))

func _get_weapon_attack_symbol(item: Dictionary) -> String:
	var explicit_symbol = str(item.get("weapon_attack_symbol", "")).strip_edges().to_lower()
	if explicit_symbol == "arco":
		return "arco"
	var granted_icons = item.get("granted_icons", [])
	if granted_icons is Array:
		for raw_icon in granted_icons:
			if str(raw_icon).strip_edges().to_lower() == "arco":
				return "arco"
	return "spada"

func _normalize_equipment_slot(slot_id: String) -> String:
	if slot_id == "armor" or slot_id == "accessory":
		return slot_id
	return "weapon"

func _get_equipment_slot_label(slot_id: String) -> String:
	match _normalize_equipment_slot(slot_id):
		"armor":
			return "Armatura"
		"accessory":
			return "Accessorio"
		_:
			return "Arma"

func _apply_starting_objects(starting_objects: Array) -> void:
	if starting_objects.is_empty():
		_recalculate_equipment_stats()
		_update_ability_label()
		return
	var object_index: Dictionary = {}
	for enemy_entry in _read_enemy_database():
		if str(enemy_entry.get("category", "")) != "object":
			continue
		object_index[str(enemy_entry.get("id", ""))] = enemy_entry
	for object_id in starting_objects:
		var object_data = object_index.get(str(object_id), {})
		if not (object_data is Dictionary) or object_data.is_empty():
			continue
		var slot_id = _normalize_equipment_slot(str(object_data.get("equipment_slot", "weapon")))
		_remove_existing_equipment_tokens(slot_id)
		current_equipment[slot_id] = object_data.duplicate(true)
		_add_object_granted_tokens(object_data)
	_recalculate_equipment_stats()
	_update_ability_label()

func _add_object_granted_tokens(object_data: Dictionary) -> void:
	var granted_icons = object_data.get("granted_icons", object_data.get("requirements", []))
	if not (granted_icons is Array):
		return
	var durability_mode = str(object_data.get("granted_durability_mode", "exhaustible")).strip_edges().to_lower()
	if durability_mode != "ephemeral" and durability_mode != "perennial":
		durability_mode = "exhaustible"
	var remaining_uses = max(1, int(object_data.get("granted_remaining_uses", 1)))
	if durability_mode != "ephemeral":
		remaining_uses = 1
	var object_id = str(object_data.get("id", ""))
	var object_name = str(object_data.get("name", "Oggetto"))
	var slot_id = _normalize_equipment_slot(str(object_data.get("equipment_slot", "weapon")))
	var activation_cost_type = str(object_data.get("activation_cost_type", "none")).strip_edges().to_lower()
	var activation_cost_amount = max(0, int(object_data.get("activation_cost_amount", 0)))
	for raw_icon in granted_icons:
		var token_data = _create_loadout_result_data({
			"symbol_id": str(raw_icon),
			"durability_mode": durability_mode,
			"remaining_uses": remaining_uses
		})
		if token_data.is_empty():
			continue
		token_data["source_object_id"] = object_id
		token_data["source_object_name"] = object_name
		token_data["source_equipment_slot"] = slot_id
		token_data["activation_cost_type"] = activation_cost_type
		token_data["activation_cost_amount"] = activation_cost_amount
		_add_token_to_tray(token_data)

func _add_token_to_tray(result: Dictionary) -> void:
	var tray_slot := _create_drop_slot(tray_slot_color)
	tray_slot.custom_minimum_size = Vector2(96, 96)
	tray_slot.set_meta("remove_when_empty", true)
	token_tray.add_child(tray_slot)
	var token := TextureRect.new()
	token.set_script(RESULT_TOKEN_SCRIPT)
	token.call("setup", _normalize_result_data(result))
	tray_slot.call("place_token", token)
	_refresh_token_cost_state_in_slot(tray_slot)

func _handle_destroyed_object_token(token_data: Dictionary) -> void:
	var object_id = str(token_data.get("source_object_id", ""))
	if object_id.is_empty():
		return
	var object_name = str(token_data.get("source_object_name", "Oggetto"))
	var slot_id = _normalize_equipment_slot(str(token_data.get("source_equipment_slot", "weapon")))
	_destroy_equipment_object(slot_id, object_id, object_name)

func _destroy_equipment_object(slot_id: String, object_id: String, object_name: String) -> void:
	var equipped = current_equipment.get(slot_id, {})
	if not (equipped is Dictionary):
		return
	if str(equipped.get("id", "")) != object_id:
		return
	current_equipment[slot_id] = {}
	_remove_tokens_from_source_object(object_id)
	_recalculate_equipment_stats()
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)
	_pending_status_messages.append("L'oggetto %s e stato distrutto." % object_name)

func _remove_tokens_from_source_object(object_id: String) -> void:
	for slot in token_tray.get_children():
		_remove_source_token_from_slot(slot, object_id)
	for slot in _slot_by_cell.values():
		_remove_source_token_from_slot(slot, object_id)

func _remove_source_token_from_slot(slot, object_id: String) -> void:
	if slot == null or not slot.has_method("has_token") or not slot.call("has_token"):
		return
	var token = slot.call("get_token") as Control
	if token == null or not token.has_method("get_result_data"):
		return
	var token_data = token.call("get_result_data") as Dictionary
	if str(token_data.get("source_object_id", "")) != object_id:
		return
	var removed = slot.call("clear_token") as Control
	if removed != null:
		removed.queue_free()
	if slot.get_parent() == token_tray and bool(slot.get_meta("remove_when_empty", false)):
		token_tray.remove_child(slot)
		slot.queue_free()

func _remove_existing_equipment_tokens(slot_id: String) -> void:
	var equipped = current_equipment.get(slot_id, {})
	if not (equipped is Dictionary) or equipped.is_empty():
		return
	var object_id = str(equipped.get("id", ""))
	if object_id.is_empty():
		return
	_remove_tokens_from_source_object(object_id)

func _compose_status_text(base_text: String) -> String:
	var parts: Array[String] = []
	var cleaned_base = base_text.strip_edges()
	if not cleaned_base.is_empty():
		parts.append(cleaned_base)
	for message in _pending_status_messages:
		if message.strip_edges().is_empty():
			continue
		parts.append(message.strip_edges())
	_pending_status_messages.clear()
	return " ".join(parts)
