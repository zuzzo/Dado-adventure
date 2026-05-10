extends Node

@export var modules: Array[PackedScene] = []

@onready var modules_root: Node = $Modules

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_load_modules()

func _load_modules() -> void:
	for module_scene in modules:
		if module_scene == null:
			continue
		var module_instance := module_scene.instantiate()
		if module_instance == null:
			continue
		modules_root.add_child(module_instance)
