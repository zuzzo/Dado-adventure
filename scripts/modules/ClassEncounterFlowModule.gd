extends Node

const CHARACTER_IMAGE_DIR := "res://assets/characters"
const DICE_ICON_PATHS := {
	"spada": "res://assets/dice/spada.png",
	"scudo": "res://assets/dice/scudo1.png",
	"magia": "res://assets/dice/magia1.png",
	"ladro": "res://assets/dice/ladro1.png",
	"moneta": "res://assets/dice/moneta1.png"
}
const CLASS_LOADOUTS := {
	"Guerriero": ["spada", "spada", "scudo"],
	"Mago": ["magia", "magia", "scudo"],
	"Ladro": ["spada", "ladro", "scudo"],
	"Warlock": ["spada", "scudo", "magia"]
}
const CLASS_HP := {
	"Guerriero": 10,
	"Mago": 6,
	"Ladro": 8,
	"Warlock": 7
}

@export var spada_dice_scene: PackedScene
@export var scudo_dice_scene: PackedScene
@export var magia_dice_scene: PackedScene
@export var ladro_dice_scene: PackedScene
@export var moneta_dice_scene: PackedScene

@onready var dice_roll_module: Node3D = $DiceRollModule
@onready var battle_board_module: Control = $BattleBoardModule
@onready var selection_screen: Control = $SelectionScreen
@onready var roll_overlay: Control = $RollOverlay
@onready var roll_info: Label = $RollOverlay/OverlayTop/RollInfo
@onready var continue_hint: Label = $RollOverlay/OverlayTop/ContinueHint
@onready var character_name_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterName
@onready var character_stats_label: Label = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterStats
@onready var character_image: TextureRect = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/CharacterImagePanel/CharacterImageMargin/CharacterImageCenter/CharacterImage
@onready var loadout_row: HBoxContainer = $SelectionScreen/Center/SelectionRow/PreviewPanel/PreviewMargin/PreviewVBox/LoadoutRow

var _pending_results: Array = []
var _waiting_for_continue := false
var _selected_class_hp := 0

func _ready() -> void:
	_ensure_character_directory()
	_bind_selection_buttons()
	dice_roll_module.roll_completed.connect(_on_roll_completed)
	_show_character_preview("Guerriero")

func _input(event):
	if not _waiting_for_continue:
		return
	var should_continue := false
	if event is InputEventKey and event.pressed and not event.echo:
		should_continue = true
	elif event is InputEventMouseButton and event.pressed:
		should_continue = true
	if should_continue:
		get_viewport().set_input_as_handled()
		_show_battle_board()

func _bind_selection_buttons() -> void:
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/WarriorButton.pressed.connect(_on_warrior_pressed)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/MageButton.pressed.connect(_on_mage_pressed)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/ThiefButton.pressed.connect(_on_thief_pressed)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/WarlockButton.pressed.connect(_on_warlock_pressed)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/WarriorButton.mouse_entered.connect(_on_warrior_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/MageButton.mouse_entered.connect(_on_mage_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/ThiefButton.mouse_entered.connect(_on_thief_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/WarlockButton.mouse_entered.connect(_on_warlock_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/WarriorButton.focus_entered.connect(_on_warrior_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/MageButton.focus_entered.connect(_on_mage_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/ThiefButton.focus_entered.connect(_on_thief_hovered)
	$SelectionScreen/Center/SelectionRow/VBox/Buttons/WarlockButton.focus_entered.connect(_on_warlock_hovered)

func _on_warrior_pressed():
	_show_character_preview("Guerriero")
	_start_class_flow("Guerriero", [spada_dice_scene, spada_dice_scene, scudo_dice_scene])

func _on_mage_pressed():
	_show_character_preview("Mago")
	_start_class_flow("Mago", [magia_dice_scene, magia_dice_scene, scudo_dice_scene])

func _on_thief_pressed():
	_show_character_preview("Ladro")
	_start_class_flow("Ladro", [spada_dice_scene, ladro_dice_scene, scudo_dice_scene])

func _on_warlock_pressed():
	_show_character_preview("Warlock")
	_start_class_flow("Warlock", [spada_dice_scene, scudo_dice_scene, magia_dice_scene])

func _on_warrior_hovered():
	_show_character_preview("Guerriero")

func _on_mage_hovered():
	_show_character_preview("Mago")

func _on_thief_hovered():
	_show_character_preview("Ladro")

func _on_warlock_hovered():
	_show_character_preview("Warlock")

func _start_class_flow(_character_class, dice_loadout):
	_selected_class_hp = int(CLASS_HP.get(_character_class, 0))
	selection_screen.visible = false
	battle_board_module.visible = false
	dice_roll_module.visible = true
	roll_overlay.visible = false
	_waiting_for_continue = false
	_pending_results.clear()
	dice_roll_module.call("set_dice_scenes_for_roll", dice_loadout)
	dice_roll_module.call("roll_dice", dice_loadout.size())

func _on_roll_completed(results):
	_pending_results = results.duplicate(true)
	_waiting_for_continue = true
	dice_roll_module.visible = true
	roll_overlay.visible = false

func _show_battle_board():
	_waiting_for_continue = false
	dice_roll_module.visible = false
	roll_overlay.visible = false
	battle_board_module.visible = true
	battle_board_module.set_roll_results(_pending_results)
	battle_board_module.refresh_random_enemy()

func _ensure_character_directory():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHARACTER_IMAGE_DIR))

func _show_character_preview(character_name):
	character_name_label.text = character_name
	character_stats_label.text = "Punti Vita: %d" % int(CLASS_HP.get(character_name, 0))
	var image_path = _get_character_image_path(character_name)
	if ResourceLoader.exists(image_path):
		character_image.texture = load(image_path)
	else:
		character_image.texture = null
	_build_loadout_preview(character_name)

func _get_character_image_path(character_name):
	match character_name:
		"Guerriero":
			return "%s/Guerriero.png" % CHARACTER_IMAGE_DIR
		"Mago":
			return "%s/Mago.png" % CHARACTER_IMAGE_DIR
		"Ladro":
			return "%s/Ladro.png" % CHARACTER_IMAGE_DIR
		"Warlock":
			return "%s/Warlock.png" % CHARACTER_IMAGE_DIR
		_:
			return "%s/%s.png" % [CHARACTER_IMAGE_DIR, character_name]

func _build_loadout_preview(character_name):
	for child in loadout_row.get_children():
		child.queue_free()
	var loadout = CLASS_LOADOUTS.get(character_name, [])
	for dice_name in loadout:
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
		var icon_path := str(DICE_ICON_PATHS.get(str(dice_name), ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		icon.tooltip_text = str(dice_name).capitalize()
		center.add_child(icon)
