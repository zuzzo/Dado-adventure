extends Control

const ENEMIES_DIR := "res://assets/enemies"
const DATABASE_DIR := "res://data/enemies"
const DATABASE_PATH := "res://data/enemies/enemy_database.json"

@onready var enemy_list: ItemList = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/EnemyList
@onready var status_label: Label = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/StatusLabel
@onready var name_input: LineEdit = $Margin/Root/RightPanel/RightMargin/RightVBox/NameInput
@onready var hp_input: SpinBox = $Margin/Root/RightPanel/RightMargin/RightVBox/StatsGrid/HpInput
@onready var strength_input: SpinBox = $Margin/Root/RightPanel/RightMargin/RightVBox/StatsGrid/StrengthInput
@onready var reward_input: SpinBox = $Margin/Root/RightPanel/RightMargin/RightVBox/StatsGrid/RewardInput
@onready var image_path_input: LineEdit = $Margin/Root/RightPanel/RightMargin/RightVBox/ImageRow/ImagePathInput
@onready var enemy_preview: TextureRect = $Margin/Root/RightPanel/RightMargin/RightVBox/PreviewPanel/PreviewMargin/PreviewCenter/EnemyPreview
@onready var file_dialog: FileDialog = $FileDialog

var enemy_database: Array[Dictionary] = []
var selected_index: int = -1
var pending_image_source_path: String = ""
var pending_image_project_path: String = ""

func _ready() -> void:
	_bind_events()
	_ensure_directories()
	_load_database()
	if enemy_database.is_empty():
		_clear_form()

func _bind_events() -> void:
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/NewButton.pressed.connect(_on_new_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/DeleteButton.pressed.connect(_on_delete_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/ActionButtons/SaveButton.pressed.connect(_on_save_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/ActionButtons/ExportButton.pressed.connect(_on_export_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/ActionButtons/ReloadButton.pressed.connect(_load_database)
	$Margin/Root/RightPanel/RightMargin/RightVBox/ImageRow/ChooseImageButton.pressed.connect(_on_choose_image_pressed)
	$Margin/Root/RightPanel/RightMargin/RightVBox/FormButtons/ApplyButton.pressed.connect(_on_apply_pressed)
	$Margin/Root/RightPanel/RightMargin/RightVBox/FormButtons/ResetButton.pressed.connect(_clear_form)
	enemy_list.item_selected.connect(_on_enemy_selected)
	file_dialog.file_selected.connect(_on_file_selected)

func _ensure_directories() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ENEMIES_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATABASE_DIR))

func _load_database() -> void:
	enemy_database.clear()
	var database_abs := ProjectSettings.globalize_path(DATABASE_PATH)
	if FileAccess.file_exists(database_abs):
		var file := FileAccess.open(database_abs, FileAccess.READ)
		if file != null:
			var json_text := file.get_as_text()
			var parsed: Variant = JSON.parse_string(json_text)
			if parsed is Array:
				for entry in parsed:
					if entry is Dictionary:
						enemy_database.append(entry)
	refresh_enemy_list()
	if enemy_database.is_empty():
		selected_index = -1
		_set_status("Database vuoto. Crea il primo nemico.")
		_clear_form()
	else:
		selected_index = clamp(selected_index, 0, enemy_database.size() - 1)
		enemy_list.select(selected_index)
		_load_enemy_into_form(selected_index)
		_set_status("Database caricato da %s" % DATABASE_PATH)

func refresh_enemy_list() -> void:
	enemy_list.clear()
	for enemy in enemy_database:
		enemy_list.add_item(str(enemy.get("name", "Nemico senza nome")))

func _on_new_pressed() -> void:
	selected_index = -1
	enemy_list.deselect_all()
	_clear_form()
	_set_status("Scheda pronta per un nuovo nemico.")

func _on_delete_pressed() -> void:
	if selected_index < 0 or selected_index >= enemy_database.size():
		_set_status("Seleziona un nemico da eliminare.")
		return
	var deleted_name := str(enemy_database[selected_index].get("name", "Nemico"))
	enemy_database.remove_at(selected_index)
	selected_index = -1
	refresh_enemy_list()
	_clear_form()
	_write_database()
	_set_status("%s eliminato dal database." % deleted_name)

func _on_save_pressed() -> void:
	if not _save_current_enemy():
		return
	_write_database()
	_set_status("Database salvato in %s" % DATABASE_PATH)

func _on_export_pressed() -> void:
	if not _save_current_enemy():
		return
	_write_database()
	_set_status("JSON esportato e pronto per il gioco.")

func _on_apply_pressed() -> void:
	if _save_current_enemy():
		_set_status("Scheda aggiornata in memoria. Salva o esporta per fissarla nel JSON.")

func _on_enemy_selected(index: int) -> void:
	selected_index = index
	_load_enemy_into_form(index)
	_set_status("Modifica il nemico selezionato e salva il database.")

func _on_choose_image_pressed() -> void:
	file_dialog.popup_centered_ratio(0.75)

func _on_file_selected(path: String) -> void:
	pending_image_source_path = path
	var file_name := path.get_file()
	pending_image_project_path = "%s/%s" % [ENEMIES_DIR, file_name]
	image_path_input.text = pending_image_project_path
	_update_preview_from_absolute(path)
	_set_status("Immagine selezionata. Applica o salva per copiarla nel progetto.")

func _save_current_enemy() -> bool:
	var enemy_name := name_input.text.strip_edges()
	if enemy_name.is_empty():
		_set_status("Inserisci il nome della carta.")
		return false

	var image_project_path := image_path_input.text.strip_edges()
	if pending_image_source_path != "":
		image_project_path = _copy_selected_image()
		if image_project_path.is_empty():
			return false

	var enemy_record := {
		"id": _slugify(enemy_name),
		"name": enemy_name,
		"image": image_project_path,
		"hp": int(hp_input.value),
		"strength": int(strength_input.value),
		"reward": int(reward_input.value)
	}

	if selected_index >= 0 and selected_index < enemy_database.size():
		enemy_database[selected_index] = enemy_record
	else:
		enemy_database.append(enemy_record)
		selected_index = enemy_database.size() - 1

	refresh_enemy_list()
	enemy_list.select(selected_index)
	_load_enemy_into_form(selected_index)
	return true

func _copy_selected_image() -> String:
	if pending_image_source_path.is_empty():
		return image_path_input.text.strip_edges()
	var source_abs := pending_image_source_path
	var target_project_path := pending_image_project_path
	var target_abs := ProjectSettings.globalize_path(target_project_path)
	var result := DirAccess.copy_absolute(source_abs, target_abs)
	if result != OK and source_abs != target_abs:
		_set_status("Impossibile copiare l'immagine selezionata.")
		return ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	image_path_input.text = target_project_path
	_update_preview_from_project(target_project_path)
	return target_project_path

func _write_database() -> void:
	var database_abs := ProjectSettings.globalize_path(DATABASE_PATH)
	var file := FileAccess.open(database_abs, FileAccess.WRITE)
	if file == null:
		_set_status("Impossibile scrivere il database JSON.")
		return
	file.store_string(JSON.stringify(enemy_database, "\t"))

func _load_enemy_into_form(index: int) -> void:
	if index < 0 or index >= enemy_database.size():
		return
	var enemy := enemy_database[index]
	name_input.text = str(enemy.get("name", ""))
	hp_input.value = float(enemy.get("hp", 1))
	strength_input.value = float(enemy.get("strength", 0))
	reward_input.value = float(enemy.get("reward", 0))
	image_path_input.text = str(enemy.get("image", ""))
	pending_image_source_path = ""
	pending_image_project_path = ""
	_update_preview_from_project(image_path_input.text)

func _clear_form() -> void:
	name_input.text = ""
	hp_input.value = 10
	strength_input.value = 3
	reward_input.value = 1
	image_path_input.text = ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	enemy_preview.texture = null

func _update_preview_from_project(project_path: String) -> void:
	if project_path.is_empty() or not ResourceLoader.exists(project_path):
		enemy_preview.texture = null
		return
	enemy_preview.texture = load(project_path)

func _update_preview_from_absolute(abs_path: String) -> void:
	var image := Image.new()
	if image.load(abs_path) != OK:
		enemy_preview.texture = null
		return
	var texture := ImageTexture.create_from_image(image)
	enemy_preview.texture = texture

func _slugify(text: String) -> String:
	var slug := text.to_lower().strip_edges()
	for ch in [" ", "-", ".", ",", ";", ":", "/", "\\", "'", "\"", "(", ")", "[", "]"]:
		slug = slug.replace(ch, "_")
	while slug.contains("__"):
		slug = slug.replace("__", "_")
	while slug.begins_with("_"):
		slug = slug.substr(1)
	while slug.ends_with("_"):
		slug = slug.left(slug.length() - 1)
	return slug

func _set_status(message: String) -> void:
	status_label.text = message
