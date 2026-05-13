extends Control

signal back_requested

const EffectTextParser = preload("res://scripts/core/EffectTextParser.gd")
const LOADOUT_SLOT_SCRIPT = preload("res://scripts/ui/CharacterLoadoutSlot.gd")
const LOADOUT_TOKEN_SCRIPT = preload("res://scripts/ui/CharacterLoadoutToken.gd")
const CHARACTERS_DIR := "res://assets/characters"
const DATABASE_DIR := "res://data/characters"
const DATABASE_PATH := "res://data/characters/character_database.json"
const ENEMY_DATABASE_PATH := "res://data/enemies/enemy_database.json"
const MIN_LOADOUT_SLOTS := 6
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

@onready var right_vbox = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox
@onready var character_list = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/CharacterList
@onready var status_label = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/StatusLabel
@onready var name_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/NameInput
@onready var image_path_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ImageRow/ImagePathInput
@onready var hp_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/HpInput
@onready var dice_count_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DiceCountLabel
@onready var starting_loadout_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/StartingLoadoutText
@onready var ability_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/AbilityText
@onready var character_preview = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CharacterPreview
@onready var preview_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewName
@onready var card_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardName
@onready var card_hp = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardHp
@onready var preview_loadout_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewDiceCount
@onready var preview_ability_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewAbilityText
@onready var file_dialog = $FileDialog

var character_database: Array = []
var object_library: Array[Dictionary] = []
var selected_index: int = -1
var pending_image_source_path: String = ""
var pending_image_project_path: String = ""
var _context_token = null
var _selected_starting_objects: Array[String] = []
var mp_input: SpinBox
var max_trace_length_input: SpinBox
var object_picker: OptionButton
var selected_objects_list: ItemList
var loadout_palette: FlowContainer
var loadout_grid: GridContainer
var loadout_help_label: Label
var loadout_buttons: HBoxContainer
var add_loadout_slot_button: Button
var remove_loadout_slot_button: Button
var token_mode_menu: PopupMenu
var ephemeral_dialog: ConfirmationDialog
var ephemeral_uses_input: SpinBox

func _ready():
	_build_runtime_editor_ui()
	_bind_events()
	_ensure_directories()
	_load_object_library()
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
	ability_text.text_changed.connect(_on_ability_changed)
	if mp_input != null:
		mp_input.value_changed.connect(_on_mp_changed)
	if max_trace_length_input != null:
		max_trace_length_input.value_changed.connect(_on_max_trace_length_changed)
	if object_picker != null:
		var add_button = object_picker.get_parent().get_node("AddObjectButton") as Button
		var remove_button = selected_objects_list.get_parent().get_node("SelectedObjectActions/RemoveObjectButton") as Button
		add_button.pressed.connect(_on_add_starting_object_pressed)
		remove_button.pressed.connect(_on_remove_starting_object_pressed)
		selected_objects_list.item_activated.connect(_on_selected_object_activated)
	if add_loadout_slot_button != null:
		add_loadout_slot_button.pressed.connect(_on_add_loadout_slot_pressed)
	if remove_loadout_slot_button != null:
		remove_loadout_slot_button.pressed.connect(_on_remove_loadout_slot_pressed)
	if token_mode_menu != null:
		token_mode_menu.id_pressed.connect(_on_token_menu_id_pressed)
	if ephemeral_dialog != null:
		ephemeral_dialog.confirmed.connect(_on_ephemeral_confirmed)

func _ensure_directories():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHARACTERS_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATABASE_DIR))

func _build_runtime_editor_ui():
	dice_count_label.text = "Icone Base"
	starting_loadout_text.visible = false

	var mp_label: Label = Label.new()
	mp_label.name = "MpLabel"
	mp_label.text = "Mana Iniziale"
	right_vbox.add_child(mp_label)
	right_vbox.move_child(mp_label, hp_input.get_index() + 1)

	mp_input = SpinBox.new()
	mp_input.name = "MpInput"
	mp_input.min_value = 0
	mp_input.max_value = 99
	mp_input.value = 0
	right_vbox.add_child(mp_input)
	right_vbox.move_child(mp_input, mp_label.get_index() + 1)

	var max_trace_label: Label = Label.new()
	max_trace_label.name = "MaxTraceLabel"
	max_trace_label.text = "Lunghezza Massima Traccia"
	right_vbox.add_child(max_trace_label)
	right_vbox.move_child(max_trace_label, mp_input.get_index() + 1)

	max_trace_length_input = SpinBox.new()
	max_trace_length_input.name = "MaxTraceLengthInput"
	max_trace_length_input.min_value = 2
	max_trace_length_input.max_value = 8
	max_trace_length_input.value = 4
	right_vbox.add_child(max_trace_length_input)
	right_vbox.move_child(max_trace_length_input, max_trace_label.get_index() + 1)

	var objects_label: Label = Label.new()
	objects_label.name = "StartingObjectsLabel"
	objects_label.text = "Oggetti Di Partenza"
	right_vbox.add_child(objects_label)
	right_vbox.move_child(objects_label, max_trace_length_input.get_index() + 1)

	var objects_panel: VBoxContainer = VBoxContainer.new()
	objects_panel.name = "StartingObjectsPanel"
	objects_panel.add_theme_constant_override("separation", 8)
	right_vbox.add_child(objects_panel)
	right_vbox.move_child(objects_panel, objects_label.get_index() + 1)

	var object_row: HBoxContainer = HBoxContainer.new()
	object_row.name = "ObjectPickerRow"
	object_row.add_theme_constant_override("separation", 8)
	objects_panel.add_child(object_row)

	object_picker = OptionButton.new()
	object_picker.name = "ObjectPicker"
	object_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	object_row.add_child(object_picker)

	var add_object_button: Button = Button.new()
	add_object_button.name = "AddObjectButton"
	add_object_button.text = "Aggiungi"
	object_row.add_child(add_object_button)

	selected_objects_list = ItemList.new()
	selected_objects_list.name = "SelectedObjectsList"
	selected_objects_list.custom_minimum_size = Vector2(0, 100)
	selected_objects_list.select_mode = ItemList.SELECT_MULTI
	objects_panel.add_child(selected_objects_list)

	var selected_actions: HBoxContainer = HBoxContainer.new()
	selected_actions.name = "SelectedObjectActions"
	objects_panel.add_child(selected_actions)

	var remove_object_button: Button = Button.new()
	remove_object_button.name = "RemoveObjectButton"
	remove_object_button.text = "Rimuovi Selezionati"
	selected_actions.add_child(remove_object_button)

	var loadout_panel: VBoxContainer = VBoxContainer.new()
	loadout_panel.name = "LoadoutEditorPanel"
	loadout_panel.add_theme_constant_override("separation", 10)
	right_vbox.add_child(loadout_panel)
	right_vbox.move_child(loadout_panel, starting_loadout_text.get_index() + 1)

	var palette_label: Label = Label.new()
	palette_label.text = "Trascina le icone base negli spazi. Click destro su una icona per scegliere Effimera, Esauribile o Perenne."
	palette_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_panel.add_child(palette_label)

	loadout_palette = FlowContainer.new()
	loadout_palette.name = "LoadoutPalette"
	loadout_palette.add_theme_constant_override("h_separation", 8)
	loadout_palette.add_theme_constant_override("v_separation", 8)
	loadout_panel.add_child(loadout_palette)

	loadout_buttons = HBoxContainer.new()
	loadout_buttons.name = "LoadoutButtons"
	loadout_buttons.add_theme_constant_override("separation", 8)
	loadout_panel.add_child(loadout_buttons)

	add_loadout_slot_button = Button.new()
	add_loadout_slot_button.name = "AddLoadoutSlotButton"
	add_loadout_slot_button.text = "Aggiungi Spazio"
	loadout_buttons.add_child(add_loadout_slot_button)

	remove_loadout_slot_button = Button.new()
	remove_loadout_slot_button.name = "RemoveLoadoutSlotButton"
	remove_loadout_slot_button.text = "Rimuovi Spazio"
	loadout_buttons.add_child(remove_loadout_slot_button)

	loadout_grid = GridContainer.new()
	loadout_grid.name = "LoadoutGrid"
	loadout_grid.columns = 4
	loadout_grid.add_theme_constant_override("h_separation", 10)
	loadout_grid.add_theme_constant_override("v_separation", 10)
	loadout_panel.add_child(loadout_grid)

	loadout_help_label = Label.new()
	loadout_help_label.name = "LoadoutHelpLabel"
	loadout_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_panel.add_child(loadout_help_label)

	token_mode_menu = PopupMenu.new()
	token_mode_menu.name = "TokenModeMenu"
	token_mode_menu.add_item("Effimera", 0)
	token_mode_menu.add_item("Esauribile", 1)
	token_mode_menu.add_item("Perenne", 2)
	token_mode_menu.add_separator()
	token_mode_menu.add_item("Rimuovi icona", 3)
	add_child(token_mode_menu)

	ephemeral_dialog = ConfirmationDialog.new()
	ephemeral_dialog.name = "EphemeralDialog"
	ephemeral_dialog.title = "Configura Icona Effimera"
	var dialog_vbox: VBoxContainer = VBoxContainer.new()
	dialog_vbox.add_theme_constant_override("separation", 8)
	ephemeral_dialog.add_child(dialog_vbox)
	var dialog_label: Label = Label.new()
	dialog_label.text = "Numero di utilizzi dell'icona effimera"
	dialog_vbox.add_child(dialog_label)
	ephemeral_uses_input = SpinBox.new()
	ephemeral_uses_input.min_value = 1
	ephemeral_uses_input.max_value = 12
	ephemeral_uses_input.value = 3
	dialog_vbox.add_child(ephemeral_uses_input)
	add_child(ephemeral_dialog)

	_build_loadout_palette()

func _load_object_library():
	object_library.clear()
	object_picker.clear()
	if not FileAccess.file_exists(ENEMY_DATABASE_PATH):
		return
	var file = FileAccess.open(ENEMY_DATABASE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return
	for entry in parsed:
		if not (entry is Dictionary):
			continue
		if str(entry.get("category", "")) != "object":
			continue
		object_library.append(entry.duplicate(true))
	object_library.sort_custom(_sort_object_entries)
	for object_entry in object_library:
		var object_name: String = str(object_entry.get("name", "Oggetto"))
		object_picker.add_item(object_name)
		object_picker.set_item_metadata(object_picker.get_item_count() - 1, str(object_entry.get("id", "")))

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
	var deleted_name: String = str(character_database[selected_index].get("name", "Personaggio"))
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

func _on_mp_changed(_value):
	_update_preview()

func _on_max_trace_length_changed(_value):
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
	var starting_loadout = _extract_loadout_from_slots()
	if starting_loadout.is_empty():
		_set_status("Inserisci almeno un simbolo nel set iniziale.")
		return false
	var character_record = {
		"id": _slugify(character_name),
		"name": character_name,
		"image": image_project_path,
		"hp": int(hp_input.value),
		"mp": int(mp_input.value),
		"max_trace_length": int(max_trace_length_input.value),
		"starting_objects": _selected_starting_objects.duplicate(),
		"starting_loadout": starting_loadout,
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
	mp_input.value = float(character.get("mp", 0))
	max_trace_length_input.value = float(character.get("max_trace_length", 4))
	_selected_starting_objects = _normalize_starting_objects(character.get("starting_objects", []))
	_refresh_selected_objects_list()
	_populate_loadout_slots(character.get("starting_loadout", []))
	ability_text.text = str(character.get("ability_text", ""))
	pending_image_source_path = ""
	pending_image_project_path = ""
	_update_preview_from_project(image_path_input.text)
	_update_preview()

func _clear_form():
	name_input.text = ""
	image_path_input.text = ""
	hp_input.value = 6
	mp_input.value = 0
	max_trace_length_input.value = 4
	_selected_starting_objects.clear()
	_refresh_selected_objects_list()
	_populate_loadout_slots([
		{"symbol_id": "spada", "durability_mode": "exhaustible", "remaining_uses": 1},
		{"symbol_id": "spada", "durability_mode": "exhaustible", "remaining_uses": 1},
		{"symbol_id": "cuore", "durability_mode": "exhaustible", "remaining_uses": 1}
	])
	ability_text.text = ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	character_preview.texture = null
	_update_preview()

func _update_preview():
	preview_name.text = name_input.text if not name_input.text.is_empty() else "Nome Personaggio"
	card_name.text = preview_name.text
	card_hp.text = "%d PV | %d PM | Traccia %d" % [int(hp_input.value), int(mp_input.value), int(max_trace_length_input.value)]
	var loadout = _extract_loadout_from_slots()
	preview_loadout_text.text = "Icone Base: %s\nOggetti Partenza: %s" % [_summarize_loadout(loadout), _summarize_starting_objects()]
	preview_ability_text.text = ability_text.text if not ability_text.text.is_empty() else "-"

func _update_preview_from_project(project_path):
	if project_path.is_empty():
		character_preview.texture = null
		return
	if ResourceLoader.exists(project_path):
		character_preview.texture = load(project_path)
		return
	var absolute_path = ProjectSettings.globalize_path(project_path)
	var image := Image.new()
	if image.load(absolute_path) == OK:
		character_preview.texture = ImageTexture.create_from_image(image)
		return
	character_preview.texture = null

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
	var character_name: String = str(character.get("name", "Personaggio senza nome"))
	var image_path: String = str(character.get("image", ""))
	var starting_loadout: Array = []
	var raw_starting_loadout = character.get("starting_loadout", [])
	if raw_starting_loadout is Array:
		for entry in raw_starting_loadout:
			var loadout_entry = _normalize_loadout_entry(entry)
			if not loadout_entry.is_empty():
				starting_loadout.append(loadout_entry)
	if starting_loadout.is_empty():
		var dice_count: int = int(character.get("starting_dice_count", 0))
		if dice_count <= 0 and character.get("starting_dice", []) is Array:
			dice_count = (character.get("starting_dice", []) as Array).size()
		if dice_count <= 0:
			dice_count = 1
		for i in dice_count:
			starting_loadout.append(_build_loadout_entry("spada"))
	var ability_value: String = str(character.get("ability_text", ""))
	var ability_effects = character.get("ability_effects", EffectTextParser.parse_character_ability_effects(ability_value))
	return {
		"id": str(character.get("id", _slugify(character_name))),
		"name": character_name,
		"image": image_path,
		"hp": int(character.get("hp", 1)),
		"mp": int(character.get("mp", 0)),
		"max_trace_length": max(2, int(character.get("max_trace_length", 4))),
		"starting_objects": _normalize_starting_objects(character.get("starting_objects", [])),
		"starting_loadout": starting_loadout,
		"ability_text": ability_value,
		"ability_effects": ability_effects
	}

func _set_status(message):
	status_label.text = message

func _normalize_loadout_symbol(raw_symbol: String) -> String:
	var symbol = raw_symbol.to_lower().strip_edges()
	if LOADOUT_ICON_PATHS.has(symbol):
		return symbol
	return ""

func _build_loadout_palette():
	for child in loadout_palette.get_children():
		child.queue_free()
	for symbol_id in LOADOUT_ICON_PATHS.keys():
		var token = create_loadout_token_instance(symbol_id, str(LOADOUT_ICON_PATHS[symbol_id]), _build_loadout_entry(symbol_id), true)
		loadout_palette.add_child(token)

func _populate_loadout_slots(loadout: Array):
	for child in loadout_grid.get_children():
		child.queue_free()
	var normalized_entries: Array = []
	for entry in loadout:
		var normalized = _normalize_loadout_entry(entry)
		if not normalized.is_empty():
			normalized_entries.append(normalized)
	var slot_count = max(MIN_LOADOUT_SLOTS, normalized_entries.size())
	for slot_index in slot_count:
		var slot = _create_loadout_slot()
		loadout_grid.add_child(slot)
		if slot_index < normalized_entries.size():
			var entry = normalized_entries[slot_index]
			var symbol_id = str(entry.get("symbol_id", ""))
			var token = create_loadout_token_instance(symbol_id, _get_icon_path(symbol_id), entry)
			slot.call("place_token", token)
	notify_loadout_changed()

func _on_add_loadout_slot_pressed():
	loadout_grid.add_child(_create_loadout_slot())
	notify_loadout_changed()

func _on_remove_loadout_slot_pressed():
	if loadout_grid.get_child_count() <= 1:
		return
	var last_slot = loadout_grid.get_child(loadout_grid.get_child_count() - 1)
	if last_slot != null:
		last_slot.queue_free()
	notify_loadout_changed()

func _create_loadout_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.set_script(LOADOUT_SLOT_SCRIPT)
	slot.custom_minimum_size = Vector2(84, 84)
	slot.set_meta("editor_module", self)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.24, 1)
	style.border_color = Color(0.4, 0.48, 0.62, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	slot.add_theme_stylebox_override("panel", style)
	return slot

func create_loadout_token_instance(symbol_id: String, texture_path: String, config: Dictionary, palette_token := false) -> Control:
	var token := TextureRect.new()
	token.set_script(LOADOUT_TOKEN_SCRIPT)
	token.call("setup", symbol_id, texture_path, config, self, palette_token)
	return token

func notify_loadout_changed():
	starting_loadout_text.text = JSON.stringify(_extract_loadout_from_slots())
	loadout_help_label.text = "Icone base: %d | Oggetti partenza: %d" % [_extract_loadout_from_slots().size(), _selected_starting_objects.size()]
	_update_preview()

func open_loadout_token_menu(token):
	_context_token = token
	var mouse_position = get_viewport().get_mouse_position()
	token_mode_menu.popup(Rect2i(int(mouse_position.x), int(mouse_position.y), 1, 1))

func _on_token_menu_id_pressed(id: int):
	if _context_token == null:
		return
	var config = _context_token.call("get_config") as Dictionary
	match id:
		0:
			ephemeral_uses_input.value = float(max(1, int(config.get("remaining_uses", 3))))
			ephemeral_dialog.popup_centered(Vector2i(320, 120))
		1:
			config["durability_mode"] = "exhaustible"
			config["remaining_uses"] = 1
			_context_token.call("set_config", config)
			notify_loadout_changed()
		2:
			config["durability_mode"] = "perennial"
			config["remaining_uses"] = 1
			_context_token.call("set_config", config)
			notify_loadout_changed()
		3:
			var slot = _context_token.call("get_slot")
			if slot != null and slot.has_method("clear_token"):
				var removed = slot.call("clear_token")
				if removed != null:
					removed.queue_free()
			notify_loadout_changed()

func _on_ephemeral_confirmed():
	if _context_token == null:
		return
	var config = _context_token.call("get_config") as Dictionary
	config["durability_mode"] = "ephemeral"
	config["remaining_uses"] = int(ephemeral_uses_input.value)
	_context_token.call("set_config", config)
	notify_loadout_changed()

func _extract_loadout_from_slots() -> Array:
	var loadout: Array = []
	for slot in loadout_grid.get_children():
		if not (slot is PanelContainer):
			continue
		if not slot.has_method("has_token") or not slot.call("has_token"):
			continue
		var token = slot.call("get_token")
		if token == null or not token.has_method("get_config"):
			continue
		var entry = _normalize_loadout_entry(token.call("get_config"))
		if not entry.is_empty():
			loadout.append(entry)
	return loadout

func _normalize_loadout_entry(entry) -> Dictionary:
	if entry is Dictionary:
		var symbol_id = _normalize_loadout_symbol(str(entry.get("symbol_id", entry.get("id", ""))))
		if symbol_id.is_empty():
			return {}
		var durability_mode = str(entry.get("durability_mode", "exhaustible")).to_lower().strip_edges()
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
	var symbol = _normalize_loadout_symbol(str(entry))
	if symbol.is_empty():
		return {}
	return _build_loadout_entry(symbol)

func _build_loadout_entry(symbol_id: String, durability_mode := "exhaustible", remaining_uses := 1) -> Dictionary:
	return {
		"symbol_id": symbol_id,
		"durability_mode": durability_mode,
		"remaining_uses": max(1, int(remaining_uses))
	}

func _normalize_starting_objects(raw_objects) -> Array[String]:
	var objects: Array[String] = []
	if raw_objects is Array:
		for entry in raw_objects:
			var object_id: String = str(entry).strip_edges()
			if object_id.is_empty():
				continue
			objects.append(object_id)
	return objects

func _refresh_selected_objects_list():
	selected_objects_list.clear()
	for object_id in _selected_starting_objects:
		var object_data = _find_object_by_id(object_id)
		var display_name = object_id
		if not object_data.is_empty():
			display_name = str(object_data.get("name", object_id))
		selected_objects_list.add_item(display_name)
		selected_objects_list.set_item_metadata(selected_objects_list.get_item_count() - 1, object_id)
	notify_loadout_changed()

func _find_object_by_id(object_id: String) -> Dictionary:
	for object_entry in object_library:
		if str(object_entry.get("id", "")) == object_id:
			return object_entry
	return {}

func _on_add_starting_object_pressed():
	if object_picker.get_item_count() == 0:
		_set_status("Non ci sono oggetti nella libreria.")
		return
	if object_picker.selected < 0:
		return
	var selected_id = str(object_picker.get_item_metadata(object_picker.selected))
	if selected_id.is_empty():
		return
	_selected_starting_objects.append(selected_id)
	_refresh_selected_objects_list()
	_set_status("Oggetto iniziale aggiunto.")

func _on_remove_starting_object_pressed():
	if selected_objects_list.get_item_count() == 0:
		return
	var selected_indices = selected_objects_list.get_selected_items()
	if selected_indices.is_empty():
		_set_status("Seleziona uno o piu oggetti iniziali da rimuovere.")
		return
	var kept: Array[String] = []
	for item_index in selected_objects_list.get_item_count():
		if selected_objects_list.is_selected(item_index):
			continue
		kept.append(str(selected_objects_list.get_item_metadata(item_index)))
	_selected_starting_objects = kept
	_refresh_selected_objects_list()
	_set_status("Oggetti iniziali aggiornati.")

func _on_selected_object_activated(index: int):
	if index < 0 or index >= selected_objects_list.get_item_count():
		return
	var object_id = str(selected_objects_list.get_item_metadata(index))
	var removed := false
	var kept: Array[String] = []
	for entry in _selected_starting_objects:
		if not removed and entry == object_id:
			removed = true
			continue
		kept.append(entry)
	_selected_starting_objects = kept
	_refresh_selected_objects_list()
	_set_status("Oggetto iniziale rimosso.")

func _sort_object_entries(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("name", "")) < str(b.get("name", ""))

func _get_icon_path(symbol_id: String) -> String:
	return str(LOADOUT_ICON_PATHS.get(symbol_id, ""))

func _summarize_loadout(loadout: Array) -> String:
	if loadout.is_empty():
		return "-"
	var parts: Array[String] = []
	for entry in loadout:
		var normalized = _normalize_loadout_entry(entry)
		if normalized.is_empty():
			continue
		var symbol_id: String = str(normalized.get("symbol_id", ""))
		var durability_mode: String = str(normalized.get("durability_mode", "exhaustible"))
		match durability_mode:
			"ephemeral":
				parts.append("%s[E%d]" % [symbol_id, int(normalized.get("remaining_uses", 1))])
			"perennial":
				parts.append("%s[P]" % symbol_id)
			_:
				parts.append("%s[R]" % symbol_id)
	return ", ".join(parts)

func _summarize_starting_objects() -> String:
	if _selected_starting_objects.is_empty():
		return "-"
	var names: Array[String] = []
	for object_id in _selected_starting_objects:
		var object_data = _find_object_by_id(object_id)
		names.append(str(object_data.get("name", object_id)))
	return ", ".join(names)
