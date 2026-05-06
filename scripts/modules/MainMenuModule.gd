extends Control

const GAME_SCENE := preload("res://scenes/modules/ClassEncounterFlowModule.tscn")
const ENEMY_EDITOR_SCENE := preload("res://scenes/modules/EnemyEditorModule.tscn")
const CHARACTER_EDITOR_SCENE := preload("res://scenes/modules/CharacterEditorModule.tscn")

@onready var status_label = $Margin/Root/MenuPanel/MenuMargin/MenuVBox/StatusLabel
@onready var content_root = $Margin/Root/ContentPanel/ContentRoot

var active_module = null

func _ready():
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/GameButton.pressed.connect(_on_game_pressed)
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/EnemyEditorButton.pressed.connect(_on_enemy_editor_pressed)
	$Margin/Root/MenuPanel/MenuMargin/MenuVBox/ButtonsRow/CharacterEditorButton.pressed.connect(_on_character_editor_pressed)

func _on_game_pressed():
	_open_module(GAME_SCENE, "Gioco aperto.")

func _on_enemy_editor_pressed():
	_open_module(ENEMY_EDITOR_SCENE, "Editor mostri aperto.")

func _on_character_editor_pressed():
	_open_module(CHARACTER_EDITOR_SCENE, "Editor personaggi aperto.")

func _open_module(scene_resource, status_text):
	if active_module != null and is_instance_valid(active_module):
		active_module.queue_free()
	active_module = scene_resource.instantiate()
	if active_module == null:
		status_label.text = "Impossibile aprire il modulo richiesto."
		return
	content_root.add_child(active_module)
	if active_module is Control:
		active_module.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_label.text = status_text
