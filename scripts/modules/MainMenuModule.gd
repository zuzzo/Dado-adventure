extends Control

const GAME_SCENE := preload("res://scenes/modules/ClassEncounterFlowModule.tscn")
const ENEMY_EDITOR_SCENE := preload("res://scenes/modules/EnemyEditorModule.tscn")
const CHARACTER_EDITOR_SCENE := preload("res://scenes/modules/CharacterEditorModule.tscn")
const DUNGEON_SCENE := preload("res://scenes/modules/DungeonGeneratorModule.tscn")

@onready var status_label = $Margin/Root/MenuPanel/MenuMargin/MenuVBox/StatusLabel
@onready var background = $Background
@onready var content_root = $Margin/Root/ContentPanel/ContentRoot
@onready var menu_margin = $Margin
@onready var game_root = $GameRoot

var active_module = null
var active_module_host = null

func _ready():
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/GameButton.pressed.connect(_on_game_pressed)
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/EnemyEditorButton.pressed.connect(_on_enemy_editor_pressed)
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/CharacterEditorButton.pressed.connect(_on_character_editor_pressed)
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/DungeonButton.pressed.connect(_on_dungeon_pressed)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if active_module == null:
			get_tree().quit()
			return
		_close_active_module()
		status_label.text = "Tornato al menu principale."

func _on_game_pressed():
	_open_module(GAME_SCENE, "Gioco aperto.")

func _on_enemy_editor_pressed():
	_open_module(ENEMY_EDITOR_SCENE, "Editor mostri aperto.")

func _on_character_editor_pressed():
	_open_module(CHARACTER_EDITOR_SCENE, "Editor personaggi aperto.")

func _on_dungeon_pressed():
	_open_module(DUNGEON_SCENE, "Generatore dungeon aperto.")

func _open_module(scene_resource, status_text):
	_close_active_module()
	active_module = scene_resource.instantiate()
	if active_module == null:
		status_label.text = "Impossibile aprire il modulo richiesto."
		return
	active_module_host = game_root
	background.visible = false
	menu_margin.visible = false
	game_root.visible = true
	active_module_host.add_child(active_module)
	if active_module is Control:
		active_module.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if active_module.has_signal("back_requested"):
		active_module.back_requested.connect(_on_module_back_requested)
	status_label.text = status_text

func _on_module_back_requested():
	_close_active_module()
	status_label.text = "Tornato al menu principale."

func _close_active_module():
	if active_module != null and is_instance_valid(active_module):
		active_module.queue_free()
	active_module = null
	active_module_host = null
	background.visible = true
	menu_margin.visible = true
	game_root.visible = false
