extends Control

const CHARACTERS_DIR := "res://assets/characters"
const DATABASE_DIR := "res://data/characters"
const DATABASE_PATH := "res://data/characters/character_database.json"
const REQUIREMENT_SLOT_SCRIPT := preload("res://scripts/ui/EnemyRequirementSlot.gd")
const REQUIREMENT_TOKEN_SCRIPT := preload("res://scripts/ui/EnemyRequirementToken.gd")
const DICE_PALETTE := [
	{"id": "spada", "path": "res://assets/dice/spada.png"},
	{"id": "scudo", "path": "res://assets/dice/scudo1.png"},
	{"id": "moneta", "path": "res://assets/dice/moneta1.png"},
	{"id": "magia", "path": "res://assets/dice/magia1.png"},
	{"id": "ladro", "path": "res://assets/dice/ladro1.png"},
	{"id": "arco", "path": "res://assets/dice/arco1.png"}
]

@onready var character_list = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/CharacterList
@onready var status_label = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/StatusLabel
@onready var name_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/NameInput
@onready var image_path_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ImageRow/ImagePathInput
@onready var hp_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/HpInput
@onready var ability_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/AbilityText
@onready var dice_palette = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DicePalette
@onready var dice_slots = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DiceSlots
@onready var character_preview = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/CharacterPreview
@onready var preview_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewName
@onready var preview_hp = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewBottomPanel/PreviewBottomMargin/PreviewBottomVBox/PreviewHp
@onready var preview_dice_row = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewBottomPanel/PreviewBottomMargin/PreviewBottomVBox/PreviewDiceRow
@onready var preview_ability_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewBottomPanel/PreviewBottomMargin/PreviewBottomVBox/PreviewAbilityText
@onready var file_dialog = $FileDialog

var character_database: Array = []
var selected_index := -1
var pending_image_source_path := ""
var pending_image_project_path := ""

func _ready():
	_bind_events()
	_ensure_directories()
	_build_dice_palette()
	_load_database()
	if dice_slots.get_child_count() == 0:
		_add_dice_slot()
	_update_preview()

func _bind_events():
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/NewButton.pressed.connect(_on_new_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/Toolbar/DeleteButton.pressed.connect(_on_delete_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/SaveButton.pressed.connect(_on_save_pressed)
	$Margin/Root/LeftPanel/LeftMargin/LeftVBox/ReloadButton.pressed.connect(_load_database)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ImageRow/ChooseImageButton.pressed.connect(_on_choose_image_pressed)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ApplyButton.pressed.connect(_on_apply_pressed)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ResetButton.pressed.connect(_clear_form)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/BottomActions/SaveButtonLarge.pressed.connect(_on_save_pressed)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/BottomActions/ReloadButtonLarge.pressed.connect(_load_database)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DiceButtons/AddDiceSlotButton.pressed.connect(_add_dice_slot)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DiceButtons/RemoveDiceSlotButton.pressed.connect(_remove_dice_slot)
	character_list.item_selected.connect(_on_character_selected)
	file_dialog.file_selected.connect(_on_file_selected)
	name_input.text_changed.connect(_update_preview)
	hp_input.value_changed.connect(_on_hp_changed)
	ability_text.text_changed.connect(_update_preview)

func _ensure_directories():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHARACTERS_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATABASE_DIR))

func _build_dice_palette():
	_clear_children_now(dice_palette)
	for dice_data in DICE_PALETTE:
		var slot = _create_slot()
		slot.custom_minimum_size = Vector2(78, 78)
		dice_palette.add_child(slot)
		var token = TextureRect.new()
		token.set_script(REQUIREMENT_TOKEN_SCRIPT)
		token.call("setup", dice_data["id"], dice_data["path"], true)
		slot.call("place_token", token)

func _add_dice_slot():
	var slot = _create_slot()
	slot.custom_minimum_size = Vector2(78, 78)
	dice_slots.add_child(slot)
	_update_preview()

func _remove_dice_slot():
	if dice_slots.get_child_count() <= 1:
		return
	var last_slot = dice_slots.get_child(dice_slots.get_child_count() - 1)
	last_slot.queue_free()
	_update_preview()

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

func _save_current_character():
	var character_name = name_input.text.strip_edges()
	if character_name.is_empty():
		_set_status("Inserisci il nome del personaggio.")
		return false
	var starting_dice = _get_dice_data()
	if starting_dice.is_empty():
		_set_status("Definisci almeno un dado di partenza.")
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
		"starting_dice": starting_dice,
		"ability_text": ability_text.text
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
	ability_text.text = str(character.get("ability_text", ""))
	pending_image_source_path = ""
	pending_image_project_path = ""
	_update_preview_from_project(image_path_input.text)
	_load_dice(character.get("starting_dice", []))
	_update_preview()

func _clear_form():
	name_input.text = ""
	image_path_input.text = ""
	hp_input.value = 6
	ability_text.text = ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	character_preview.texture = null
	_clear_children_now(dice_slots)
	_add_dice_slot()
	_update_preview()

func _load_dice(starting_dice):
	_clear_children_now(dice_slots)
	for dice_id in starting_dice:
		var slot = _create_slot()
		slot.custom_minimum_size = Vector2(78, 78)
		dice_slots.add_child(slot)
		var dice_name = str(dice_id)
		var texture_path = _get_dice_icon_path(dice_name)
		if texture_path.is_empty():
			continue
		var token = TextureRect.new()
		token.set_script(REQUIREMENT_TOKEN_SCRIPT)
		token.call("setup", dice_name, texture_path, false)
		slot.call("place_token", token)
	if dice_slots.get_child_count() == 0:
		_add_dice_slot()

func _get_dice_data():
	var starting_dice: Array = []
	for slot in dice_slots.get_children():
		if slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token")
			if token != null:
				starting_dice.append(str(token.get("icon_id")))
	return starting_dice

func _update_preview():
	preview_name.text = name_input.text if not name_input.text.is_empty() else "Nome Personaggio"
	preview_hp.text = "Punti Vita: %d" % int(hp_input.value)
	preview_ability_text.text = ability_text.text if not ability_text.text.is_empty() else "-"
	_clear_children_now(preview_dice_row)
	for dice_id in _get_dice_data():
		var texture_path = _get_dice_icon_path(dice_id)
		if texture_path.is_empty():
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 52)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(texture_path):
			icon.texture = load(texture_path)
		icon.tooltip_text = dice_id.capitalize()
		preview_dice_row.add_child(icon)

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
	var starting_dice: Array = []
	var raw_starting_dice = character.get("starting_dice", [])
	if raw_starting_dice is Array:
		for dice_id in raw_starting_dice:
			starting_dice.append(str(dice_id))
	return {
		"id": str(character.get("id", _slugify(character_name))),
		"name": character_name,
		"image": image_path,
		"hp": int(character.get("hp", 1)),
		"starting_dice": starting_dice,
		"ability_text": str(character.get("ability_text", ""))
	}

func _create_slot():
	var slot = PanelContainer.new()
	slot.set_script(REQUIREMENT_SLOT_SCRIPT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.145098, 0.184314, 0.247059, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.313726, 0.396078, 0.533333, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	slot.add_theme_stylebox_override("panel", style)
	return slot

func _get_dice_icon_path(dice_id):
	for dice_data in DICE_PALETTE:
		if str(dice_data["id"]) == dice_id:
			return str(dice_data["path"])
	return ""

func _set_status(message):
	status_label.text = message

func _clear_children_now(node):
	for child in node.get_children():
		node.remove_child(child)
		child.free()
