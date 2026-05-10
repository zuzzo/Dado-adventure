extends Control

signal reroll_requested(count, cells)
signal character_hp_changed(hp)
signal player_stats_changed(hp, gold)

const MAX_GRID_SIZE := 5
const ENEMY_DATABASE_PATH := "res://data/enemies/enemy_database.json"
const ENEMY_BACK_IMAGE_PATH := "res://assets/enemies/dorso.png"
const ENEMY_ICON_PATHS := {
	"spada": "res://assets/dice/spada.png",
	"scudo": "res://assets/dice/cuore1.png",
	"cuore": "res://assets/dice/cuore1.png",
	"moneta": "res://assets/dice/moneta1.png",
	"magia": "res://assets/dice/magia1.png",
	"ladro": "res://assets/dice/ladro1.png",
	"arco": "res://assets/dice/arco1.png"
}
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
@onready var enemy_image: TextureRect = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/EnemyImage
@onready var card_name_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardName
@onready var requirements_row: HBoxContainer = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/RequirementsRow
@onready var damage_line_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/DamageLine
@onready var flee_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/FleeLine
@onready var reward_value_label: Label = $EnemyArea/EnemyMargin/EnemyCard/CardMargin/CardVBox/ImagePanel/ImageMargin/ImageCenter/PreviewCard/CardInfo/CardInfoVBox/RewardLine
@onready var reveal_hint_label: Label = $EnemyArea/EnemyMargin/RevealHint

var current_results: Array[Dictionary] = []
var current_enemy: Dictionary = {}
var current_enemy_requirements: Array = []
var enemy_revealed := false
var current_character_name := ""
var current_character_hp := 0
var current_character_ability := ""
var current_character_ability_effects: Array = []
var current_gold := 0
var _slot_by_cell := {}
var _hover_line_type := ""
var _hover_line_index := -1
var _exhausted_cells := []
var _reroll_locked_cells := []
var _pending_reroll_resolution := false
var _pending_reroll_cells := []

func _ready() -> void:
	_build_grid()
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
	current_gold = 0
	_exhausted_cells.clear()
	_reroll_locked_cells.clear()
	_pending_reroll_resolution = false
	_pending_reroll_cells.clear()
	_hover_line_type = ""
	_hover_line_index = -1
	_build_result_tray()
	_prepare_hidden_enemy()
	_refresh_grid_visuals()

func set_character_context(character_name: String, hp: int, ability_text: String, ability_effects: Array = []) -> void:
	current_character_name = character_name
	current_character_hp = hp
	current_character_ability = ability_text
	current_character_ability_effects = ability_effects.duplicate(true)
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)

func refresh_random_enemy() -> void:
	_prepare_hidden_enemy()

func _build_grid() -> void:
	if grid_layer == null:
		return
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
				slot.mouse_exited.connect(_on_grid_slot_mouse_exited)
				grid.add_child(slot)
				_slot_by_cell[original_cell] = slot
			else:
				var spacer := Control.new()
				spacer.custom_minimum_size = cell_size
				grid.add_child(spacer)
	_refresh_grid_visuals()

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

func _prepare_hidden_enemy(hint_text: String = "Piazza tutti i risultati, poi clicca direttamente la carta a destra per scoprire il nemico.") -> void:
	current_enemy = _pick_random_enemy()
	current_enemy_requirements.clear()
	var raw_requirements = current_enemy.get("requirements", [])
	if raw_requirements is Array:
		for requirement in raw_requirements:
			current_enemy_requirements.append(str(requirement))
	enemy_revealed = false
	enemy_name_label.text = "Carta Coperta"
	card_name_label.text = "Carta Coperta"
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
	damage_line_label.visible = enemy_damage > 0
	damage_line_label.text = "Danno: %d" % enemy_damage
	flee_value_label.text = "Fuga: %s" % str(current_enemy.get("flee_text", "-"))
	reward_value_label.text = "Premio: %s" % str(current_enemy.get("reward_text", "-"))
	flee_value_label.visible = false
	reward_value_label.visible = false
	reveal_hint_label.text = "Nemico scoperto."
	rest_button.disabled = false
	ability_button.disabled = false
	flee_button.disabled = false
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
		reveal_hint_label.text = "Prima piazza tutti i risultati nella griglia, poi clicca la carta."
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
	for result in results:
		var token := TextureRect.new()
		token.set_script(RESULT_TOKEN_SCRIPT)
		var result_data = result.duplicate(true)
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
	if not enemy_revealed:
		return
	if _pending_reroll_resolution:
		return
	if event is InputEventMouseMotion:
		var motion = event as InputEventMouseMotion
		var line_data = _get_line_from_slot_position(motion.position, cell)
		_set_hover_line(str(line_data.get("type", "")), int(line_data.get("index", -1)))
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		var line_data = _get_line_from_slot_position(mouse_event.position, cell)
		var line_type = str(line_data.get("type", ""))
		var line_index = int(line_data.get("index", -1))
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_commit_line_selection(line_type, line_index)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_request_line_reroll(line_type, line_index)

func _on_grid_slot_mouse_exited() -> void:
	_set_hover_line("", -1)

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
		elif _pending_reroll_resolution and _pending_reroll_cells.has(cell):
			fill = reroll_target_cell_color
		elif _hover_line_type == "row" and cell.y == _hover_line_index:
			fill = highlight_cell_color
		elif _hover_line_type == "column" and cell.x == _hover_line_index:
			fill = highlight_cell_color
		_apply_slot_fill(slot, fill)

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

func _commit_line_selection(line_type: String, line_index: int) -> void:
	_resolve_line_selection(line_type, line_index, true)

func _resolve_line_selection(line_type: String, line_index: int, finish_action: bool) -> void:
	if line_type.is_empty():
		return
	var line_cells: Array = []
	for cell in _slot_by_cell.keys():
		if line_type == "row" and cell.y == line_index:
			line_cells.append(cell)
		elif line_type == "column" and cell.x == line_index:
			line_cells.append(cell)
	if line_cells.is_empty():
		return
	var used_symbol_entries: Array = []
	for cell in line_cells:
		if _exhausted_cells.has(cell):
			continue
		_exhausted_cells.append(cell)
		var slot = _slot_by_cell[cell] as PanelContainer
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token") as Control
			if token != null:
				if token.has_method("set_exhausted"):
					token.call("set_exhausted", true)
				if token.has_method("get_result_data"):
					used_symbol_entries.append(token.call("get_result_data"))
	_collect_gold_from_symbols(used_symbol_entries)
	_collect_healing_from_symbols(used_symbol_entries)
	_consume_enemy_requirements(used_symbol_entries)
	_set_hover_line("", -1)
	_refresh_grid_visuals()
	if finish_action:
		_end_player_action()

func _request_line_reroll(line_type: String, line_index: int) -> void:
	if line_type.is_empty():
		return
	if _pending_reroll_resolution:
		return
	var reroll_cells: Array = []
	for cell in _slot_by_cell.keys():
		if _exhausted_cells.has(cell):
			continue
		if line_type == "row" and cell.y == line_index:
			var row_slot = _slot_by_cell[cell] as PanelContainer
			if row_slot != null and row_slot.has_method("has_token") and row_slot.call("has_token"):
				reroll_cells.append(cell)
		elif line_type == "column" and cell.x == line_index:
			var column_slot = _slot_by_cell[cell] as PanelContainer
			if column_slot != null and column_slot.has_method("has_token") and column_slot.call("has_token"):
				reroll_cells.append(cell)
	if reroll_cells.is_empty():
		return
	_reroll_locked_cells.clear()
	for cell in reroll_cells:
		var slot = _slot_by_cell[cell] as PanelContainer
		if slot != null and slot.has_method("clear_token"):
			var token = slot.call("clear_token") as Control
			if token != null:
				token.queue_free()
		_reroll_locked_cells.append(cell)
	_set_hover_line("", -1)
	_refresh_grid_visuals()
	reveal_hint_label.text = "Caselle marcate. Rilancia e poi trascina i nuovi risultati solo in queste posizioni."
	reroll_requested.emit(reroll_cells.size(), reroll_cells)

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
		for i in amount:
			var requirement_index = current_enemy_requirements.find(symbol_id)
			if requirement_index >= 0:
				current_enemy_requirements.remove_at(requirement_index)
	_build_requirements_row()

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

func _disable_random_active_die() -> void:
	var available_cells: Array = []
	for cell in _slot_by_cell.keys():
		if _exhausted_cells.has(cell):
			continue
		var slot = _slot_by_cell[cell] as PanelContainer
		if slot != null and slot.has_method("has_token") and slot.call("has_token"):
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
			if token != null and token.has_method("set_exhausted"):
				token.call("set_exhausted", false)
	_set_hover_line("", -1)
	_refresh_grid_visuals()

func _handle_enemy_defeated() -> void:
	var reward_text = str(current_enemy.get("reward_text", "")).strip_edges()
	var next_hint = "Nemico sconfitto. Nuova carta pronta da scoprire."
	if not reward_text.is_empty():
		next_hint = "Nemico sconfitto. Premio incassato: %s. Nuova carta pronta da scoprire." % reward_text
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
		return
	if not _all_results_placed():
		return
	if not _all_pending_reroll_cells_filled():
		return
	_pending_reroll_resolution = false
	_pending_reroll_cells.clear()
	_refresh_grid_visuals()
	reveal_hint_label.text = "Rilancio confermato."
	_end_player_action()

func _end_player_action() -> void:
	if not _enemy_survived_player_action():
		_handle_enemy_defeated()
		return
	current_character_hp = max(current_character_hp - 1, 0)
	character_hp_changed.emit(current_character_hp)
	_update_ability_label()
	player_stats_changed.emit(current_character_hp, current_gold)
	reveal_hint_label.text = "Il nemico colpisce per 1 danno. Ora tocca di nuovo a te."

func _update_ability_label() -> void:
	ability_label.text = "%s | PV: %d | Oro: %d | Abilita: %s" % [current_character_name, current_character_hp, current_gold, current_character_ability]

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
	token_data["ephemeral"] = true
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
	var best_line = _find_best_active_line()
	if best_line.is_empty():
		reveal_hint_label.text = "Non ci sono altre righe o colonne utilizzabili."
		return false
	_resolve_line_selection(str(best_line.get("type", "")), int(best_line.get("index", -1)), false)
	reveal_hint_label.text = "Abilita usata: hai risolto una linea aggiuntiva."
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
		"symbol_id": symbol_id,
		"symbol_texture": load(icon_path),
		"dice_type": "ability",
		"dice_name": "Ability"
	}

func _find_best_active_line() -> Dictionary:
	var best_line := {}
	var best_score := -1
	for cell in _slot_by_cell.keys():
		var row_score = _count_active_tokens_in_line("row", cell.y)
		if row_score > best_score:
			best_score = row_score
			best_line = {"type": "row", "index": cell.y}
		var column_score = _count_active_tokens_in_line("column", cell.x)
		if column_score > best_score:
			best_score = column_score
			best_line = {"type": "column", "index": cell.x}
	return best_line

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
			count += 1
	return count
