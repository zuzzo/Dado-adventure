extends Node

const CHARACTER_DATABASE_PATH := "res://data/characters/character_database.json"
const CHARACTER_IMAGE_DIR := "res://assets/characters"
const GENERIC_DIE_ICON_PATH := "res://assets/dice/1.png"

@export var spada_dice_scene: PackedScene
@export var scudo_dice_scene: PackedScene
@export var magia_dice_scene: PackedScene
@export var ladro_dice_scene: PackedScene
@export var moneta_dice_scene: PackedScene
@export var base_dice_scene: PackedScene

@onready var dice_roll_module: Node3D = $DiceRollModule
@onready var battle_board_module: Control = $BattleBoardModule
@onready var selection_screen: Control = $SelectionScreen
@onready var hud_overlay: Control = $HudOverlay
@onready var hp_value_label: Label = $HudOverlay/HudMargin/HudPanel/HudPanelMargin/HudHBox/HpValue
@onready var gold_value_label: Label = $HudOverlay/HudMargin/HudPanel/HudPanelMargin/HudHBox/GoldValue
@onready var roll_overlay: Control = $RollOverlay
@onready var roll_info: Label = $RollOverlay/OverlayTop/OverlayPanel/OverlayPanelMargin/OverlayPanelVBox/RollInfo
@onready var continue_hint: Label = $RollOverlay/OverlayTop/OverlayPanel/OverlayPanelMargin/OverlayPanelVBox/ContinueHint
@onready var roll_results_row: HBoxContainer = $RollOverlay/OverlayTop/OverlayPanel/OverlayPanelMargin/OverlayPanelVBox/RollResultsRow
@onready var accept_roll_button: Button = $RollOverlay/OverlayTop/OverlayPanel/OverlayPanelMargin/OverlayPanelVBox/RollActionRow/AcceptRollButton
@onready var reroll_button: Button = $RollOverlay/OverlayTop/OverlayPanel/OverlayPanelMargin/OverlayPanelVBox/RollActionRow/RerollButton
@onready var character_name_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterName
@onready var character_stats_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterStats
@onready var character_ability_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterAbility
@onready var character_image: TextureRect = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterImagePanel/CharacterImageMargin/CharacterImageCenter/CharacterImage
@onready var loadout_row: HBoxContainer = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/LoadoutRow
@onready var preview_title: Label = $SelectionScreen/Center/SelectionRow/VBox/Title
@onready var preview_subtitle: Label = $SelectionScreen/Center/SelectionRow/VBox/Subtitle
@onready var warrior_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/WarriorButton
@onready var mage_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/MageButton
@onready var thief_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/ThiefButton
@onready var warlock_button: Button = $SelectionScreen/Center/SelectionRow/VBox/Buttons/WarlockButton
@onready var character_hint_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterHint
@onready var loadout_title_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/LoadoutTitle

var _pending_results: Array = []
var _waiting_for_continue := false
var _selected_class_hp := 0
var _selected_character_name := ""
var _selected_character_ability := ""
var _selected_character_ability_effects: Array = []
var _selected_starting_dice_count := 0
var _current_gold := 0
var _current_roll_loadout: Array = []
var _board_reroll_mode := false
var _pending_reroll_cells: Array = []
var _characters: Array = []
var _character_by_name := {}
var _button_character_map := {}

func _ready() -> void:
	_ensure_character_directory()
	_load_character_database()
	_bind_selection_buttons()
	_bind_roll_overlay()
	dice_roll_module.roll_completed.connect(_on_roll_completed)
	battle_board_module.reroll_requested.connect(_on_board_reroll_requested)
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

func _bind_roll_overlay() -> void:
	accept_roll_button.pressed.connect(_on_accept_roll_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)

func _configure_selection_buttons() -> void:
	preview_title.text = "Scegli Il Personaggio"
	preview_subtitle.text = "I personaggi arrivano dal database creato nell'editor"
	character_hint_label.text = "Anteprima personaggio dal file JSON"
	loadout_title_label.text = "Dadi Di Partenza"
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
	_selected_starting_dice_count = int(character.get("starting_dice_count", 0))
	_current_gold = 0
	var dice_loadout: Array = []
	for i in _selected_starting_dice_count:
		if base_dice_scene != null:
			dice_loadout.append(base_dice_scene)
	_current_roll_loadout = dice_loadout.duplicate()
	selection_screen.visible = false
	battle_board_module.visible = false
	dice_roll_module.visible = true
	hud_overlay.visible = true
	roll_overlay.visible = false
	_waiting_for_continue = false
	_pending_results.clear()
	dice_roll_module.call("set_dice_scenes_for_roll", dice_loadout)
	dice_roll_module.call("roll_dice", dice_loadout.size())

func _on_roll_completed(results):
	if _board_reroll_mode:
		_board_reroll_mode = false
		dice_roll_module.visible = false
		battle_board_module.visible = true
		battle_board_module.apply_rerolled_results(_pending_reroll_cells, results)
		_pending_reroll_cells.clear()
		return
	_pending_results = results.duplicate(true)
	dice_roll_module.visible = true
	roll_overlay.visible = true
	_update_hud()
	roll_info.text = "Punti Vita attuali: %d" % _selected_class_hp
	continue_hint.text = "Accetti il risultato oppure paghi 1 PV per rilanciare gli %d dadi?" % _selected_starting_dice_count
	_build_roll_results_preview()
	reroll_button.disabled = _selected_class_hp <= 1

func _on_accept_roll_pressed() -> void:
	_show_battle_board()

func _on_reroll_pressed() -> void:
	if _selected_class_hp <= 1:
		return
	_selected_class_hp -= 1
	_update_hud()
	roll_overlay.visible = false
	dice_roll_module.visible = true
	dice_roll_module.call("set_dice_scenes_for_roll", _current_roll_loadout)
	dice_roll_module.call("roll_dice", _selected_starting_dice_count)

func _show_battle_board():
	_waiting_for_continue = false
	dice_roll_module.visible = false
	roll_overlay.visible = false
	battle_board_module.visible = true
	battle_board_module.set_roll_results(_pending_results)
	battle_board_module.set_character_context(_selected_character_name, _selected_class_hp, _selected_character_ability, _selected_character_ability_effects)
	battle_board_module.refresh_random_enemy()
	_update_hud()

func _on_board_reroll_requested(count, cells) -> void:
	_pending_reroll_cells = cells.duplicate(true)
	_board_reroll_mode = true
	battle_board_module.visible = false
	roll_overlay.visible = false
	dice_roll_module.visible = true
	dice_roll_module.call("set_dice_scenes_for_roll", _current_roll_loadout)
	dice_roll_module.call("roll_dice", int(count))

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
	character_stats_label.text = "Punti Vita: %d" % int(character.get("hp", 0))
	character_ability_label.text = "Abilita: %s" % str(character.get("ability_text", "-"))
	var image_path = str(character.get("image", _get_character_image_path(character_name)))
	if ResourceLoader.exists(image_path):
		character_image.texture = load(image_path)
	else:
		character_image.texture = null
	_build_loadout_preview(character)

func _get_character_image_path(character_name):
	return "%s/%s.png" % [CHARACTER_IMAGE_DIR, character_name]

func _build_loadout_preview(character):
	for child in loadout_row.get_children():
		child.queue_free()
	var dice_count = int(character.get("starting_dice_count", 0))
	for i in dice_count:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(92, 92)
		loadout_row.add_child(panel)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_child(center)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(GENERIC_DIE_ICON_PATH):
			icon.texture = load(GENERIC_DIE_ICON_PATH)
		icon.tooltip_text = "Dado Base"
		center.add_child(icon)

func _build_roll_results_preview():
	for child in roll_results_row.get_children():
		child.queue_free()
	for result in _pending_results:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(88, 112)
		roll_results_row.add_child(panel)
		var vbox = VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		panel.add_child(vbox)
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = result.get("symbol_texture") as Texture2D
		icon.tooltip_text = str(result.get("label", ""))
		vbox.add_child(icon)
		var value_label = Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.text = "%s x%d" % [str(result.get("label", "")), int(result.get("value", 1))]
		vbox.add_child(value_label)

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
				var character = entry
				_characters.append(character)
				_character_by_name[str(character.get("name", ""))] = character

func _get_character_by_name(character_name):
	return _character_by_name.get(character_name, {})

func _update_hud() -> void:
	if hp_value_label != null:
		hp_value_label.text = str(_selected_class_hp)
	if gold_value_label != null:
		gold_value_label.text = "Oro: %d" % _current_gold
