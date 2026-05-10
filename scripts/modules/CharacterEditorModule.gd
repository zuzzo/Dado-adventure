extends Control

signal back_requested

const EffectTextParser = preload("res://scripts/core/EffectTextParser.gd")
const CHARACTERS_DIR := "res://assets/characters"
const DATABASE_DIR := "res://data/characters"
const DATABASE_PATH := "res://data/characters/character_database.json"

@onready var character_list = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/CharacterList
@onready var status_label = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/StatusLabel
@onready var name_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/NameInput
@onready var image_path_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ImageRow/ImagePathInput
@onready var hp_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/HpInput
@onready var dice_count_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DiceCountInput
@onready var ability_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/AbilityText
@onready var character_preview = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CharacterPreview
@onready var preview_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewName
@onready var card_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardName
@onready var card_hp = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardHp
@onready var preview_dice_count = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewDiceCount
@onready var preview_ability_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewAbilityText
@onready var file_dialog = $FileDialog

var character_database: Array = []
var selected_index := -1
var pending_image_source_path := ""
var pending_image_project_path := ""

func _ready():
	_bind_events()
	_ensure_directories()
	_load_database()
	_update_preview()

func _bind_events():
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/BackButton.pressed.connect(_on_back_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/NewButton.pressed.connect(_on_new_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/DeleteButton.pressed.connect(_on_delete_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/SaveButton.pressed.connect(_on_save_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/ReloadButton.pressed.connect(_load_database)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ImageRow/ChooseImageButton.pressed.connect(_on_choose_image_pressed)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ApplyButton.pressed.connect(_on_apply_pressed)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ResetButton.pressed.connect(_clear_form)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/BottomActions/SaveButtonLarge.pressed.connect(_on_save_pressed)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/BottomActions/ReloadButtonLarge.pressed.connect(_load_database)
	character_list.item_selected.connect(_on_character_selected)
	file_dialog.file_selected.connect(_on_file_selected)
	name_input.text_changed.connect(_on_name_changed)
	hp_input.value_changed.connect(_on_hp_changed)
	dice_count_input.value_changed.connect(_on_dice_count_changed)
	ability_text.text_changed.connect(_on_ability_changed)

func _ensure_directories():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHARACTERS_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATABASE_DIR))

func _load_database():
	character_database.clear()
	if FileAccess.file_exists(DATABASE_PATH):
		var file = FileAccess.open(DATABASE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Array:
				for entry in parsed:
					if entry is Dictionary:
						character_database.append(_normalize_character_record(entry))
	_refresh_character_list()
	if character_database.is_empty():
		selected_index = -1
		_clear_form()
		_set_status("Database vuoto. Crea il primo personaggio.")
	else:
		selected_index = clamp(selected_index, 0, character_database.size() - 1)
		character_list.select(selected_index)
		_load_character_into_form(selected_index)
		_set_status("Database caricato.")

func _refresh_character_list():
	character_list.clear()
	for character in character_database:
		character_list.add_item(str(character.get("name", "Personaggio senza nome")))

func _on_new_pressed():
	selected_index = -1
	character_list.deselect_all()
	_clear_form()
	_set_status("Scheda pronta per un nuovo personaggio.")

func _on_back_pressed():
	back_requested.emit()

func _on_delete_pressed():
	if selected_index < 0 or selected_index >= character_database.size():
		_set_status("Seleziona un personaggio da eliminare.")
		return
	var deleted_name := str(character_database[selected_index].get("name", "Personaggio"))
	character_database.remove_at(selected_index)
	selected_index = -1
	_refresh_character_list()
	_clear_form()
	_write_database()
	_set_status("%s eliminato dal database." % deleted_name)

func _on_save_pressed():
	if not _save_current_character():
		return
	_write_database()
	_set_status("Database JSON salvato.")

func _on_apply_pressed():
	if _save_current_character():
		_write_database()
		_set_status("Scheda salvata nel database JSON.")

func _on_character_selected(index):
	selected_index = index
	_load_character_into_form(index)
	_set_status("Personaggio caricato nella scheda.")

func _on_choose_image_pressed():
	file_dialog.popup_centered_ratio(0.75)

func _on_file_selected(path):
	pending_image_source_path = path
	var file_name = path.get_file()
	pending_image_project_path = "%s/%s" % [CHARACTERS_DIR, file_name]
	image_path_input.text = pending_image_project_path
	_update_preview_from_absolute(path)
	_update_preview()

func _on_hp_changed(_value):
	_update_preview()

func _on_dice_count_changed(_value):
	_update_preview()

func _on_name_changed(_text):
	_update_preview()

func _on_ability_changed():
	_update_preview()

func _save_current_character():
	var character_name = name_input.text.strip_edges()
	if character_name.is_empty():
		_set_status("Inserisci il nome del personaggio.")
		return false
	var image_project_path = image_path_input.text.strip_edges()
	if pending_image_source_path != "":
		image_project_path = _copy_selected_image()
		if image_project_path.is_empty():
			return false
	var character_record = {
		"id": _slugify(character_name),
		"name": character_name,
		"image": image_project_path,
		"hp": int(hp_input.value),
		"starting_dice_count": int(dice_count_input.value),
		"ability_text": ability_text.text,
		"ability_effects": EffectTextParser.parse_character_ability_effects(ability_text.text)
	}
	if selected_index >= 0 and selected_index < character_database.size():
		character_database[selected_index] = character_record
	else:
		character_database.append(character_record)
		selected_index = character_database.size() - 1
	_refresh_character_list()
	character_list.select(selected_index)
	_load_character_into_form(selected_index)
	return true

func _copy_selected_image():
	if pending_image_source_path.is_empty():
		return image_path_input.text.strip_edges()
	var source_abs = pending_image_source_path
	var target_project_path = pending_image_project_path
	var target_abs = ProjectSettings.globalize_path(target_project_path)
	var result = DirAccess.copy_absolute(source_abs, target_abs)
	if result != OK and source_abs != target_abs:
		_set_status("Impossibile copiare l'immagine selezionata.")
		return ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	image_path_input.text = target_project_path
	_update_preview_from_project(target_project_path)
	return target_project_path

func _write_database():
	var file = FileAccess.open(DATABASE_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Impossibile scrivere il database JSON.")
		return
	file.store_string(JSON.stringify(character_database, "\t"))

func _load_character_into_form(index):
	if index < 0 or index >= character_database.size():
		return
	var character = _normalize_character_record(character_database[index])
	character_database[index] = character
	name_input.text = str(character.get("name", ""))
	image_path_input.text = str(character.get("image", ""))
	hp_input.value = float(character.get("hp", 1))
	dice_count_input.value = float(character.get("starting_dice_count", 1))
	ability_text.text = str(character.get("ability_text", ""))
	pending_image_source_path = ""
	pending_image_project_path = ""
	_update_preview_from_project(image_path_input.text)
	_update_preview()

func _clear_form():
	name_input.text = ""
	image_path_input.text = ""
	hp_input.value = 6
	dice_count_input.value = 3
	ability_text.text = ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	character_preview.texture = null
	_update_preview()

func _update_preview():
	preview_name.text = name_input.text if not name_input.text.is_empty() else "Nome Personaggio"
	card_name.text = preview_name.text
	card_hp.text = "%d PV" % int(hp_input.value)
	preview_dice_count.text = "Dadi Di Partenza: %d" % int(dice_count_input.value)
	preview_ability_text.text = ability_text.text if not ability_text.text.is_empty() else "-"

func _update_preview_from_project(project_path):
	if project_path.is_empty() or not ResourceLoader.exists(project_path):
		character_preview.texture = null
		return
	character_preview.texture = load(project_path)

func _update_preview_from_absolute(abs_path):
	var image := Image.new()
	if image.load(abs_path) != OK:
		character_preview.texture = null
		return
	character_preview.texture = ImageTexture.create_from_image(image)

func _slugify(text):
	var slug = text.to_lower().strip_edges()
	for ch in [" ", "-", ".", ",", ";", ":", "/", "\\", "'", "\"", "(", ")", "[", "]"]:
		slug = slug.replace(ch, "_")
	while slug.contains("__"):
		slug = slug.replace("__", "_")
	while slug.begins_with("_"):
		slug = slug.substr(1)
	while slug.ends_with("_"):
		slug = slug.left(slug.length() - 1)
	return slug

func _normalize_character_record(character):
	var character_name := str(character.get("name", "Personaggio senza nome"))
	var image_path := str(character.get("image", ""))
	var dice_count := int(character.get("starting_dice_count", 0))
	if dice_count <= 0 and character.get("starting_dice", []) is Array:
		dice_count = (character.get("starting_dice", []) as Array).size()
	if dice_count <= 0:
		dice_count = 1
	var ability_value := str(character.get("ability_text", ""))
	var ability_effects = character.get("ability_effects", EffectTextParser.parse_character_ability_effects(ability_value))
	return {
		"id": str(character.get("id", _slugify(character_name))),
		"name": character_name,
		"image": image_path,
		"hp": int(character.get("hp", 1)),
		"starting_dice_count": dice_count,
		"ability_text": ability_value,
		"ability_effects": ability_effects
	}

func _set_status(message):
	status_label.text = message
