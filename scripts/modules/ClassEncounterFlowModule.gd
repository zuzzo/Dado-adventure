extends Node

const CHARACTER_DATABASE_PATH := "res://data/characters/character_database.json"
const CHARACTER_IMAGE_DIR := "res://assets/characters"
const ENEMY_DATABASE_PATH := "res://data/enemies/enemy_database.json"
const LOADOUT_ICON_PATHS := {
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

@export var spada_dice_scene: PackedScene
@export var scudo_dice_scene: PackedScene
@export var magia_dice_scene: PackedScene
@export var ladro_dice_scene: PackedScene
@export var moneta_dice_scene: PackedScene
@export var base_dice_scene: PackedScene

@onready var battle_board_module: Control = $BattleBoardModule
@onready var selection_screen: Control = $SelectionScreen
@onready var hud_overlay: Control = $HudOverlay
@onready var hp_value_label: Label = $HudOverlay/HudMargin/HudPanel/HudPanelMargin/HudHBox/HpValue
@onready var gold_value_label: Label = $HudOverlay/HudMargin/HudPanel/HudPanelMargin/HudHBox/GoldValue
@onready var hud_hbox: HBoxContainer = $HudOverlay/HudMargin/HudPanel/HudPanelMargin/HudHBox
@onready var character_name_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterName
@onready var character_stats_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterStats
@onready var character_ability_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterAbility
@onready var character_image: TextureRect = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterImagePanel/CharacterImageMargin/CharacterImageCenter/CharacterImage
@onready var loadout_row: HBoxContainer = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/LoadoutRow
@onready var preview_vbox: VBoxContainer = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox
@onready var preview_title: Label = $SelectionScreen/Center/SelectionRow/VBox/Title
@onready var preview_subtitle: Label = $SelectionScreen/Center/SelectionRow/VBox/Subtitle
@onready var warrior_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/WarriorButton
@onready var mage_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/MageButton
@onready var thief_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/ThiefButton
@onready var warlock_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/WarlockButton
@onready var character_hint_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterHint
@onready var loadout_title_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/LoadoutTitle

var _selected_class_hp: int = 0
var _selected_class_mp: int = 0
var _selected_max_trace_length: int = 4
var _selected_character_name: String = ""
var _selected_character_ability: String = ""
var _selected_character_ability_effects: Array = []
var _selected_starting_loadout: Array = []
var _selected_starting_objects: Array[String] = []
var _current_gold: int = 0
var _characters: Array = []
var _character_by_name: Dictionary = {}
var _button_character_map: Dictionary = {}
var _object_library: Dictionary = {}
var _mp_value_label: Label
var _objects_title_label: Label
var _objects_value_label: Label

func _ready() -> void:
	_ensure_runtime_preview_ui()
	_ensure_character_directory()
	_load_object_library()
	_load_character_database()
	_bind_selection_buttons()
	battle_board_module.character_hp_changed.connect(_on_board_character_hp_changed)
	battle_board_module.player_stats_changed.connect(_on_board_player_stats_changed)
	_configure_selection_buttons()
	if not _characters.is_empty():
		_show_character_preview(str(_characters[0].get("name", "")))
	_update_hud()

func _input(event):
	pass

func _bind_selection_buttons() -> void:
	for button in [warrior_button, mage_button, thief_button, warlock_button]:
		button.pressed.connect(_on_character_button_pressed.bind(button))
		button.mouse_entered.connect(_on_character_button_hovered.bind(button))
		button.focus_entered.connect(_on_character_button_hovered.bind(button))

func _configure_selection_buttons() -> void:
	preview_title.text = "Scegli Il Personaggio"
	preview_subtitle.text = "I personaggi arrivano dal database creato nell'editor"
	character_hint_label.text = "Anteprima personaggio dal file JSON"
	loadout_title_label.text = "Set Iniziale"
	var buttons = [warrior_button, mage_button, thief_button, warlock_button]
	_button_character_map.clear()
	for index in buttons.size():
		var button = buttons[index]
		if index < _characters.size():
			var character = _characters[index]
			var character_name = str(character.get("name", "Personaggio"))
			button.visible = true
			button.disabled = false
			button.text = character_name
			_button_character_map[button] = character_name
		else:
			button.visible = false
			button.disabled = true

func _on_character_button_pressed(button):
	var character_name = str(_button_character_map.get(button, ""))
	if character_name.is_empty():
		return
	_show_character_preview(character_name)
	_start_class_flow(character_name)

func _on_character_button_hovered(button):
	var character_name = str(_button_character_map.get(button, ""))
	if character_name.is_empty():
		return
	_show_character_preview(character_name)

func _start_class_flow(character_name):
	var character = _get_character_by_name(character_name)
	if character.is_empty():
		return
	_selected_character_name = str(character.get("name", ""))
	_selected_character_ability = str(character.get("ability_text", "-"))
	_selected_character_ability_effects = character.get("ability_effects", []).duplicate(true)
	_selected_class_hp = int(character.get("hp", 0))
	_selected_class_mp = int(character.get("mp", 0))
	_selected_max_trace_length = max(2, int(character.get("max_trace_length", 4)))
	_selected_starting_loadout = _normalize_starting_loadout(character.get("starting_loadout", []))
	_selected_starting_objects = _normalize_starting_objects(character.get("starting_objects", []))
	_current_gold = 0
	selection_screen.visible = false
	battle_board_module.visible = true
	hud_overlay.visible = true
	battle_board_module.reset_run_state()
	battle_board_module.start_battle(
		_selected_character_name,
		_selected_class_hp,
		_selected_class_mp,
		_selected_max_trace_length,
		_selected_character_ability,
		_selected_character_ability_effects,
		_selected_starting_loadout,
		_selected_starting_objects
	)
	_update_hud()

func _on_board_character_hp_changed(hp) -> void:
	_selected_class_hp = int(hp)
	_update_hud()

func _on_board_player_stats_changed(hp, gold) -> void:
	_selected_class_hp = int(hp)
	_current_gold = int(gold)
	_update_hud()

func _ensure_character_directory():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHARACTER_IMAGE_DIR))

func _show_character_preview(character_name):
	var character = _get_character_by_name(character_name)
	if character.is_empty():
		return
	character_name_label.text = str(character.get("name", "Personaggio"))
	character_stats_label.text = "Punti Vita: %d | Punti Magia: %d | Traccia: %d" % [int(character.get("hp", 0)), int(character.get("mp", 0)), max(2, int(character.get("max_trace_length", 4)))]
	character_ability_label.text = "Abilita: %s" % str(character.get("ability_text", "-"))
	var image_path = str(character.get("image", _get_character_image_path(character_name)))
	if ResourceLoader.exists(image_path):
		character_image.texture = load(image_path)
	else:
		character_image.texture = null
	_build_loadout_preview(character)
	_objects_value_label.text = _summarize_starting_objects(character.get("starting_objects", []))

func _get_character_image_path(character_name):
	return "%s/%s.png" % [CHARACTER_IMAGE_DIR, character_name]

func _build_loadout_preview(character):
	for child in loadout_row.get_children():
		child.queue_free()
	var loadout = _normalize_starting_loadout(character.get("starting_loadout", []))
	for entry in loadout:
		var symbol_id = str(entry.get("symbol_id", ""))
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(92, 92)
		loadout_row.add_child(panel)
		var center: CenterContainer = CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_child(center)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path = str(LOADOUT_ICON_PATHS.get(str(symbol_id), ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.tooltip_text = _build_loadout_tooltip(entry)
		center.add_child(icon)
		var badge: Label = Label.new()
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -30.0
		badge.offset_top = -22.0
		badge.offset_right = -4.0
		badge.offset_bottom = -4.0
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_constant_override("outline_size", 3)
		badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		badge.text = _get_loadout_badge(entry)
		panel.add_child(badge)
		if icon.texture == null:
			var label: Label = Label.new()
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.text = str(symbol_id)
			center.add_child(label)

func _load_character_database() -> void:
	_characters.clear()
	_character_by_name.clear()
	if not FileAccess.file_exists(CHARACTER_DATABASE_PATH):
		return
	var file = FileAccess.open(CHARACTER_DATABASE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				var character = _normalize_character_record(entry)
				_characters.append(character)
				_character_by_name[str(character.get("name", ""))] = character

func _get_character_by_name(character_name):
	return _character_by_name.get(character_name, {})

func _update_hud() -> void:
	if hp_value_label != null:
		hp_value_label.text = str(_selected_class_hp)
	if _mp_value_label != null:
		_mp_value_label.text = "MP: %d" % _selected_class_mp
	if gold_value_label != null:
		gold_value_label.text = "Oro: %d" % _current_gold

func _normalize_starting_loadout(raw_loadout) -> Array:
	var loadout: Array = []
	if raw_loadout is Array:
		for entry in raw_loadout:
			var normalized = _normalize_loadout_entry(entry)
			if not normalized.is_empty():
				loadout.append(normalized)
	return loadout

func _normalize_loadout_entry(entry) -> Dictionary:
	if entry is Dictionary:
		var symbol_id = str(entry.get("symbol_id", entry.get("id", ""))).strip_edges().to_lower()
		if symbol_id.is_empty():
			return {}
		var durability_mode = str(entry.get("durability_mode", "exhaustible")).strip_edges().to_lower()
		if durability_mode != "ephemeral" and durability_mode != "perennial":
			durability_mode = "exhaustible"
		var remaining_uses: int = max(1, int(entry.get("remaining_uses", 1)))
		if durability_mode != "ephemeral":
			remaining_uses = 1
		return {
			"symbol_id": symbol_id,
			"durability_mode": durability_mode,
			"remaining_uses": remaining_uses
		}
	var raw_symbol = str(entry).strip_edges().to_lower()
	if raw_symbol.is_empty():
		return {}
	return {
		"symbol_id": raw_symbol,
		"durability_mode": "exhaustible",
		"remaining_uses": 1
	}

func _normalize_starting_objects(raw_objects) -> Array[String]:
	var objects: Array[String] = []
	if raw_objects is Array:
		for entry in raw_objects:
			var object_id = str(entry).strip_edges()
			if object_id.is_empty():
				continue
			objects.append(object_id)
	return objects

func _normalize_character_record(character: Dictionary) -> Dictionary:
	var ability_effects = character.get("ability_effects", [])
	if not (ability_effects is Array):
		ability_effects = []
	return {
		"id": str(character.get("id", "")),
		"name": str(character.get("name", "Personaggio")),
		"image": str(character.get("image", "")),
		"hp": int(character.get("hp", 1)),
		"mp": int(character.get("mp", 0)),
		"max_trace_length": max(2, int(character.get("max_trace_length", 4))),
		"starting_objects": _normalize_starting_objects(character.get("starting_objects", [])),
		"starting_loadout": _normalize_starting_loadout(character.get("starting_loadout", [])),
		"ability_text": str(character.get("ability_text", "-")),
		"ability_effects": (ability_effects as Array).duplicate(true)
	}

func _ensure_runtime_preview_ui() -> void:
	_mp_value_label = Label.new()
	_mp_value_label.name = "MpValue"
	_mp_value_label.add_theme_font_size_override("font_size", 22)
	_mp_value_label.add_theme_color_override("font_color", Color(0.68, 0.84, 1, 1))
	_mp_value_label.add_theme_constant_override("outline_size", 3)
	_mp_value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_mp_value_label.text = "MP: 0"
	hud_hbox.add_child(_mp_value_label)
	hud_hbox.move_child(_mp_value_label, 2)

	_objects_title_label = Label.new()
	_objects_title_label.name = "ObjectsTitle"
	_objects_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objects_title_label.add_theme_font_size_override("font_size", 18)
	_objects_title_label.text = "Oggetti Iniziali"
	preview_vbox.add_child(_objects_title_label)
	preview_vbox.move_child(_objects_title_label, loadout_row.get_index() + 1)

	_objects_value_label = Label.new()
	_objects_value_label.name = "ObjectsValue"
	_objects_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objects_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objects_value_label.text = "-"
	preview_vbox.add_child(_objects_value_label)
	preview_vbox.move_child(_objects_value_label, _objects_title_label.get_index() + 1)

func _load_object_library() -> void:
	_object_library.clear()
	if not FileAccess.file_exists(ENEMY_DATABASE_PATH):
		return
	var file = FileAccess.open(ENEMY_DATABASE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for entry in parsed:
			if not (entry is Dictionary):
				continue
			if str(entry.get("category", "")) != "object":
				continue
			_object_library[str(entry.get("id", ""))] = entry.duplicate(true)

func _summarize_starting_objects(raw_objects) -> String:
	var object_ids = _normalize_starting_objects(raw_objects)
	if object_ids.is_empty():
		return "-"
	var names: Array[String] = []
	for object_id in object_ids:
		var object_data = _object_library.get(object_id, {})
		names.append(str(object_data.get("name", object_id)))
	return ", ".join(names)

func _build_loadout_tooltip(entry: Dictionary) -> String:
	var symbol_id = str(entry.get("symbol_id", ""))
	var durability_mode = str(entry.get("durability_mode", "exhaustible"))
	var mode_label = "Esauribile"
	if durability_mode == "ephemeral":
		mode_label = "Effimera"
	elif durability_mode == "perennial":
		mode_label = "Perenne"
	if durability_mode == "ephemeral":
		return "%s | %s | Usi: %d" % [symbol_id.capitalize(), mode_label, int(entry.get("remaining_uses", 1))]
	return "%s | %s" % [symbol_id.capitalize(), mode_label]

func _get_loadout_badge(entry: Dictionary) -> String:
	var durability_mode = str(entry.get("durability_mode", "exhaustible"))
	match durability_mode:
		"ephemeral":
			return "E%d" % int(entry.get("remaining_uses", 1))
		"perennial":
			return "P"
		_:
			return "R"
