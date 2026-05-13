extends Control

signal back_requested

const EffectTextParser = preload("res://scripts/core/EffectTextParser.gd")
const ENEMIES_DIR := "res://assets/enemies"
const DATABASE_DIR := "res://data/enemies"
const DATABASE_PATH := "res://data/enemies/enemy_database.json"
const REQUIREMENT_SLOT_SCRIPT := preload("res://scripts/ui/EnemyRequirementSlot.gd")
const REQUIREMENT_TOKEN_SCRIPT := preload("res://scripts/ui/EnemyRequirementToken.gd")
const CATEGORY_OPTIONS := [
	{"id": "monster", "label": "Mostro"},
	{"id": "treasure", "label": "Tesoro"},
	{"id": "trap", "label": "Trappola"},
	{"id": "stairs", "label": "Scala"},
	{"id": "event", "label": "Evento"},
	{"id": "door", "label": "Porta"},
	{"id": "object", "label": "Oggetto"}
]
const EQUIPMENT_SLOT_OPTIONS := [
	{"id": "weapon", "label": "Arma"},
	{"id": "armor", "label": "Armatura"},
	{"id": "accessory", "label": "Accessorio"}
]
const DURABILITY_OPTIONS := [
	{"id": "exhaustible", "label": "Esauribile"},
	{"id": "ephemeral", "label": "Effimera"},
	{"id": "perennial", "label": "Perenne"}
]
const ACTIVATION_COST_OPTIONS := [
	{"id": "none", "label": "Nessuno"},
	{"id": "mana", "label": "Mana"}
]
const DICE_ICON_PALETTE := [
	{"id": "spada", "path": "res://assets/icone/spada.png"},
	{"id": "scudo", "path": "res://assets/icone/scudo1.png"},
	{"id": "cuore", "path": "res://assets/icone/cuore1.png"},
	{"id": "moneta", "path": "res://assets/icone/moneta1.png"},
	{"id": "magia", "path": "res://assets/icone/magia1.png"},
	{"id": "ladro", "path": "res://assets/icone/ladro1.png"},
	{"id": "arco", "path": "res://assets/icone/arco1.png"}
]
const ITEM_ICON_PALETTE := [
	{"id": "chiave", "path": "res://assets/icone/chiave.png"},
	{"id": "corona", "path": "res://assets/icone/corona.png"},
	{"id": "cristallo", "path": "res://assets/icone/cristallo.png"},
	{"id": "monete", "path": "res://assets/icone/monete.png"},
	{"id": "pergamena", "path": "res://assets/icone/pergamena.png"},
	{"id": "pozione", "path": "res://assets/icone/pozione.png"},
	{"id": "teschio", "path": "res://assets/icone/teschio.png"},
	{"id": "torcia", "path": "res://assets/icone/torcia.png"}
]

@onready var enemy_list = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/EnemyList
@onready var status_label = $Margin/Root/LeftPanel/LeftMargin/LeftVBox/StatusLabel
@onready var damage_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DamageLabel
@onready var exhaustion_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ExhaustionLabel
@onready var flee_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/FleeLabel
@onready var reward_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/RewardLabel
@onready var name_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/NameInput
@onready var image_path_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ImageRow/ImagePathInput
@onready var category_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/CategoryInput
@onready var damage_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DamageInput
@onready var exhaustion_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ExhaustionInput
@onready var difficulty_value = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/DifficultyValue
@onready var flee_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/FleeText
@onready var reward_text = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/RewardText
@onready var equipment_slot_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/EquipmentSlotLabel
@onready var equipment_slot_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/EquipmentSlotInput
@onready var attack_bonus_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/AttackBonusLabel
@onready var attack_bonus_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/AttackBonusInput
@onready var armor_value_label = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ArmorValueLabel
@onready var armor_value_input = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/ArmorValueInput
@onready var enemy_preview = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/EnemyPreview
@onready var preview_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewName
@onready var card_name = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardName
@onready var preview_requirement_row = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewRequirementRow
@onready var preview_meta_line = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewMetaLine
@onready var preview_exhaustion_line = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewExhaustionLine
@onready var preview_requirement_title = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewRequirementTitle
@onready var preview_flee_line = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewFleeLine
@onready var preview_reward_line = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/PreviewPanel/PreviewMargin/PreviewVBox/PreviewImageCenter/PreviewCard/CardInfo/CardInfoVBox/PreviewRewardLine
@onready var icon_palette = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/IconPalette
@onready var sequence_slots = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/SequenceSlots
@onready var right_vbox = $Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox
@onready var file_dialog = $FileDialog

var enemy_database: Array = []
var selected_index := -1
var pending_image_source_path := ""
var pending_image_project_path := ""
var object_icons_label: Label
var object_icons_palette: FlowContainer
var object_icons_slots: FlowContainer
var object_icons_buttons: HBoxContainer
var object_add_icon_button: Button
var object_remove_icon_button: Button
var object_durability_label: Label
var object_durability_input: OptionButton
var object_uses_label: Label
var object_uses_input: SpinBox
var weapon_attack_count_label: Label
var weapon_attack_count_input: SpinBox
var attack_sequences_label: Label
var attack_sequences_text: TextEdit
var activation_cost_label: Label
var activation_cost_input: OptionButton
var activation_cost_amount_label: Label
var activation_cost_amount_input: SpinBox

func _ready():
	_ensure_directories()
	_build_category_options()
	_build_equipment_slot_options()
	_build_icon_palette()
	_build_object_icon_runtime_ui()
	_bind_events()
	_load_database()
	if sequence_slots.get_child_count() == 0:
		_add_sequence_slot()
	_update_form_for_category()
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
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/SequenceButtons/AddSlotButton.pressed.connect(_add_sequence_slot)
	$Margin/Root/RightPanel/RightMargin/RightScroll/RightVBox/SequenceButtons/RemoveSlotButton.pressed.connect(_remove_sequence_slot)
	enemy_list.item_selected.connect(_on_enemy_selected)
	file_dialog.file_selected.connect(_on_file_selected)
	name_input.text_changed.connect(_on_name_changed)
	category_input.item_selected.connect(_on_category_changed)
	damage_input.value_changed.connect(_on_damage_changed)
	attack_sequences_text.text_changed.connect(_update_preview)
	exhaustion_input.value_changed.connect(_on_exhaustion_changed)
	flee_text.text_changed.connect(_update_preview)
	reward_text.text_changed.connect(_update_preview)
	equipment_slot_input.item_selected.connect(_on_equipment_slot_changed)
	attack_bonus_input.value_changed.connect(_on_attack_bonus_changed)
	armor_value_input.value_changed.connect(_on_armor_value_changed)
	if weapon_attack_count_input != null:
		weapon_attack_count_input.value_changed.connect(_on_weapon_attack_count_changed)
	if activation_cost_input != null:
		activation_cost_input.item_selected.connect(_on_activation_cost_changed)
	if activation_cost_amount_input != null:
		activation_cost_amount_input.value_changed.connect(_on_activation_cost_amount_changed)
	if object_durability_input != null:
		object_durability_input.item_selected.connect(_on_object_durability_changed)
	if object_uses_input != null:
		object_uses_input.value_changed.connect(_on_object_uses_changed)
	if object_add_icon_button != null:
		object_add_icon_button.pressed.connect(_add_object_icon_slot)
	if object_remove_icon_button != null:
		object_remove_icon_button.pressed.connect(_remove_object_icon_slot)

func _ensure_directories():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ENEMIES_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATABASE_DIR))

func _build_icon_palette():
	_clear_children_now(icon_palette)
	for icon_data in _get_available_icon_palette():
		var slot = _create_slot()
		slot.custom_minimum_size = Vector2(78, 78)
		icon_palette.add_child(slot)
		var token = TextureRect.new()
		token.set_script(REQUIREMENT_TOKEN_SCRIPT)
		token.call("setup", icon_data["id"], icon_data["path"], true)
		slot.call("place_token", token)

func _build_category_options():
	category_input.clear()
	for option in CATEGORY_OPTIONS:
		category_input.add_item(str(option["label"]))

func _build_equipment_slot_options():
	equipment_slot_input.clear()
	for option in EQUIPMENT_SLOT_OPTIONS:
		equipment_slot_input.add_item(str(option["label"]))

func _build_object_icon_runtime_ui():
	attack_sequences_label = Label.new()
	attack_sequences_label.text = "Sequenze Attacco Nemico"
	right_vbox.add_child(attack_sequences_label)
	right_vbox.move_child(attack_sequences_label, damage_input.get_index() + 1)

	attack_sequences_text = TextEdit.new()
	attack_sequences_text.custom_minimum_size = Vector2(0, 110)
	attack_sequences_text.placeholder_text = "Una sequenza per riga. Esempio: spada, spada, scudo"
	right_vbox.add_child(attack_sequences_text)
	right_vbox.move_child(attack_sequences_text, attack_sequences_label.get_index() + 1)

	weapon_attack_count_label = Label.new()
	weapon_attack_count_label.text = "Attacchi Generati"
	right_vbox.add_child(weapon_attack_count_label)
	right_vbox.move_child(weapon_attack_count_label, attack_bonus_input.get_index() + 1)

	weapon_attack_count_input = SpinBox.new()
	weapon_attack_count_input.min_value = 0
	weapon_attack_count_input.max_value = 12
	weapon_attack_count_input.step = 1
	weapon_attack_count_input.value = 1
	right_vbox.add_child(weapon_attack_count_input)
	right_vbox.move_child(weapon_attack_count_input, weapon_attack_count_label.get_index() + 1)

	activation_cost_label = Label.new()
	activation_cost_label.text = "Costo Attivazione Icone"
	right_vbox.add_child(activation_cost_label)
	right_vbox.move_child(activation_cost_label, weapon_attack_count_input.get_index() + 1)

	activation_cost_input = OptionButton.new()
	for option in ACTIVATION_COST_OPTIONS:
		activation_cost_input.add_item(str(option["label"]))
	right_vbox.add_child(activation_cost_input)
	right_vbox.move_child(activation_cost_input, activation_cost_label.get_index() + 1)

	activation_cost_amount_label = Label.new()
	activation_cost_amount_label.text = "Quantita Costo"
	right_vbox.add_child(activation_cost_amount_label)
	right_vbox.move_child(activation_cost_amount_label, activation_cost_input.get_index() + 1)

	activation_cost_amount_input = SpinBox.new()
	activation_cost_amount_input.min_value = 0
	activation_cost_amount_input.max_value = 12
	activation_cost_amount_input.step = 1
	activation_cost_amount_input.value = 0
	right_vbox.add_child(activation_cost_amount_input)
	right_vbox.move_child(activation_cost_amount_input, activation_cost_amount_label.get_index() + 1)

	object_icons_label = Label.new()
	object_icons_label.text = "Icone Conferite Quando Equipaggiato"
	right_vbox.add_child(object_icons_label)
	right_vbox.move_child(object_icons_label, armor_value_input.get_index() + 1)

	object_icons_palette = FlowContainer.new()
	object_icons_palette.add_theme_constant_override("h_separation", 10)
	object_icons_palette.add_theme_constant_override("v_separation", 10)
	right_vbox.add_child(object_icons_palette)
	right_vbox.move_child(object_icons_palette, object_icons_label.get_index() + 1)

	object_icons_buttons = HBoxContainer.new()
	object_icons_buttons.add_theme_constant_override("separation", 8)
	right_vbox.add_child(object_icons_buttons)
	right_vbox.move_child(object_icons_buttons, object_icons_palette.get_index() + 1)

	object_add_icon_button = Button.new()
	object_add_icon_button.text = "Aggiungi Icona Oggetto"
	object_icons_buttons.add_child(object_add_icon_button)

	object_remove_icon_button = Button.new()
	object_remove_icon_button.text = "Rimuovi Icona Oggetto"
	object_icons_buttons.add_child(object_remove_icon_button)

	object_icons_slots = FlowContainer.new()
	object_icons_slots.add_theme_constant_override("separation", 10)
	right_vbox.add_child(object_icons_slots)
	right_vbox.move_child(object_icons_slots, object_icons_buttons.get_index() + 1)

	object_durability_label = Label.new()
	object_durability_label.text = "Durata Icone Oggetto"
	right_vbox.add_child(object_durability_label)
	right_vbox.move_child(object_durability_label, object_icons_slots.get_index() + 1)

	object_durability_input = OptionButton.new()
	for option in DURABILITY_OPTIONS:
		object_durability_input.add_item(str(option["label"]))
	right_vbox.add_child(object_durability_input)
	right_vbox.move_child(object_durability_input, object_durability_label.get_index() + 1)

	object_uses_label = Label.new()
	object_uses_label.text = "Usi Icona Effimera"
	right_vbox.add_child(object_uses_label)
	right_vbox.move_child(object_uses_label, object_durability_input.get_index() + 1)

	object_uses_input = SpinBox.new()
	object_uses_input.min_value = 1
	object_uses_input.max_value = 12
	object_uses_input.step = 1
	object_uses_input.value = 3
	right_vbox.add_child(object_uses_input)
	right_vbox.move_child(object_uses_input, object_uses_label.get_index() + 1)

	_rebuild_object_icon_palette()
	if object_icons_slots.get_child_count() == 0:
		_add_object_icon_slot()

func _rebuild_object_icon_palette():
	_clear_children_now(object_icons_palette)
	for icon_data in _get_available_icon_palette():
		var slot = _create_slot()
		slot.custom_minimum_size = Vector2(78, 78)
		object_icons_palette.add_child(slot)
		var token = TextureRect.new()
		token.set_script(REQUIREMENT_TOKEN_SCRIPT)
		token.call("setup", icon_data["id"], icon_data["path"], true)
		slot.call("place_token", token)

func _add_object_icon_slot():
	var slot = _create_slot()
	slot.custom_minimum_size = Vector2(78, 78)
	object_icons_slots.add_child(slot)
	_update_preview()

func _remove_object_icon_slot():
	if object_icons_slots.get_child_count() <= 1:
		return
	var last_slot = object_icons_slots.get_child(object_icons_slots.get_child_count() - 1)
	last_slot.queue_free()
	_update_preview()

func _add_sequence_slot():
	var slot = _create_slot()
	slot.custom_minimum_size = Vector2(78, 78)
	sequence_slots.add_child(slot)
	_update_preview()

func _remove_sequence_slot():
	if sequence_slots.get_child_count() <= 1:
		return
	var last_slot = sequence_slots.get_child(sequence_slots.get_child_count() - 1)
	last_slot.queue_free()
	_update_preview()

func _load_database():
	enemy_database.clear()
	if FileAccess.file_exists(DATABASE_PATH):
		var file = FileAccess.open(DATABASE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Array:
				for entry in parsed:
					if entry is Dictionary:
						enemy_database.append(_normalize_enemy_record(entry))
	_refresh_enemy_list()
	if enemy_database.is_empty():
		selected_index = -1
		_clear_form()
		_set_status("Database vuoto. Crea la prima carta dungeon.")
	else:
		selected_index = clamp(selected_index, 0, enemy_database.size() - 1)
		enemy_list.select(selected_index)
		_load_enemy_into_form(selected_index)
		_set_status("Database caricato.")

func _refresh_enemy_list():
	enemy_list.clear()
	for enemy in enemy_database:
		enemy_list.add_item(str(enemy.get("name", "Carta senza nome")))

func _on_new_pressed():
	selected_index = -1
	enemy_list.deselect_all()
	_clear_form()
	_set_status("Scheda pronta per una nuova carta dungeon.")

func _on_back_pressed():
	back_requested.emit()

func _on_delete_pressed():
	if selected_index < 0 or selected_index >= enemy_database.size():
		_set_status("Seleziona una carta da eliminare.")
		return
	var deleted_name := str(enemy_database[selected_index].get("name", "Carta"))
	enemy_database.remove_at(selected_index)
	selected_index = -1
	_refresh_enemy_list()
	_clear_form()
	_write_database()
	_set_status("%s eliminato dal database." % deleted_name)

func _on_save_pressed():
	if not _save_current_enemy():
		return
	_write_database()
	_set_status("Database JSON salvato.")

func _on_apply_pressed():
	if _save_current_enemy():
		_write_database()
		_set_status("Scheda salvata nel database JSON.")

func _on_enemy_selected(index):
	selected_index = index
	_load_enemy_into_form(index)
	_set_status("Carta caricata nella scheda.")

func _on_choose_image_pressed():
	file_dialog.popup_centered_ratio(0.75)

func _on_name_changed(_text):
	_update_preview()

func _on_category_changed(_index):
	_update_form_for_category()
	_update_preview()

func _on_damage_changed(_value):
	_update_preview()

func _on_exhaustion_changed(_value):
	_update_preview()

func _on_equipment_slot_changed(_index):
	_update_form_for_category()
	_update_preview()

func _on_attack_bonus_changed(_value):
	_update_preview()

func _on_armor_value_changed(_value):
	_update_preview()

func _on_weapon_attack_count_changed(_value):
	_update_preview()

func _on_activation_cost_changed(_index):
	_update_form_for_category()
	_update_preview()

func _on_activation_cost_amount_changed(_value):
	_update_preview()

func _on_file_selected(path):
	pending_image_source_path = path
	var file_name = path.get_file()
	pending_image_project_path = "%s/%s" % [ENEMIES_DIR, file_name]
	image_path_input.text = pending_image_project_path
	_update_preview_from_absolute(path)
	_update_preview()

func _save_current_enemy():
	var enemy_name = name_input.text.strip_edges()
	if enemy_name.is_empty():
		_set_status("Inserisci il nome della carta.")
		return false
	var requirements = _get_sequence_data()
	if requirements.is_empty():
		_set_status("Definisci almeno un'icona per la sconfitta.")
		return false
	var category_id = _get_selected_category_id()
	var image_project_path = image_path_input.text.strip_edges()
	if pending_image_source_path != "":
		image_project_path = _copy_selected_image()
		if image_project_path.is_empty():
			return false
	var difficulty = requirements.size()
	var outcome_text = flee_text.text
	var reward_value = reward_text.text
	var success_outcomes = _parse_outcome_lines(reward_text.text)
	var failure_outcomes = _parse_outcome_lines(flee_text.text)
	var attack_sequences = _parse_attack_sequences(attack_sequences_text.text)
	var equipment_slot = _get_selected_equipment_slot_id()
	var weapon_damage_per_hit = int(attack_bonus_input.value)
	var weapon_attack_count = int(weapon_attack_count_input.value)
	var attack_bonus = max(0, weapon_damage_per_hit - 1)
	var armor_value = int(armor_value_input.value)
	var granted_icons = _get_object_icon_sequence_data()
	var granted_durability_mode = _get_selected_object_durability_id()
	var granted_remaining_uses = int(object_uses_input.value)
	var activation_cost_type = _get_selected_activation_cost_id()
	var activation_cost_amount = int(activation_cost_amount_input.value)
	if category_id == "object" and equipment_slot == "weapon":
		granted_icons = _build_weapon_attack_icons(weapon_attack_count)
	if category_id == "treasure":
		outcome_text = flee_text.text
		reward_value = reward_text.text
	if category_id != "object":
		equipment_slot = ""
		attack_bonus = 0
		weapon_damage_per_hit = 0
		weapon_attack_count = 0
		armor_value = 0
		granted_icons = []
		granted_durability_mode = "exhaustible"
		granted_remaining_uses = 1
		activation_cost_type = "none"
		activation_cost_amount = 0
	if not _uses_damage(category_id):
		attack_sequences = []
	var enemy_record = {
		"id": _slugify(enemy_name),
		"name": enemy_name,
		"image": image_project_path,
		"category": category_id,
		"enemy_damage": int(damage_input.value),
		"attack_sequences": attack_sequences,
		"exhaustion_limit": int(exhaustion_input.value),
		"attempt_limit": _get_attempt_limit_for_category(),
		"difficulty": difficulty,
		"requirements": requirements,
		"flee_text": outcome_text,
		"failure_text": outcome_text,
		"flee_effects": EffectTextParser.parse_enemy_flee_effects(outcome_text),
		"failure_effects": EffectTextParser.parse_enemy_flee_effects(outcome_text),
		"reward_text": reward_value,
		"reward_effects": EffectTextParser.parse_enemy_reward_effects(reward_value),
		"success_outcomes": success_outcomes,
		"failure_outcomes": failure_outcomes,
		"equipment_slot": equipment_slot,
		"attack_bonus": attack_bonus,
		"weapon_attack_count": weapon_attack_count,
		"weapon_damage_per_hit": weapon_damage_per_hit,
		"armor_value": armor_value,
		"granted_icons": granted_icons,
		"granted_durability_mode": granted_durability_mode,
		"granted_remaining_uses": granted_remaining_uses,
		"activation_cost_type": activation_cost_type,
		"activation_cost_amount": activation_cost_amount
	}
	if selected_index >= 0 and selected_index < enemy_database.size():
		enemy_database[selected_index] = enemy_record
	else:
		enemy_database.append(enemy_record)
		selected_index = enemy_database.size() - 1
	_refresh_enemy_list()
	enemy_list.select(selected_index)
	_load_enemy_into_form(selected_index)
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
	file.store_string(JSON.stringify(enemy_database, "\t"))

func _load_enemy_into_form(index):
	if index < 0 or index >= enemy_database.size():
		return
	var enemy = _normalize_enemy_record(enemy_database[index])
	enemy_database[index] = enemy
	name_input.text = str(enemy.get("name", ""))
	image_path_input.text = str(enemy.get("image", ""))
	_select_category(str(enemy.get("category", "monster")))
	damage_input.value = float(enemy.get("enemy_damage", 1))
	attack_sequences_text.text = _join_attack_sequences(enemy.get("attack_sequences", []))
	var loaded_attempt_limit = int(enemy.get("attempt_limit", 0))
	var loaded_exhaustion_limit = int(enemy.get("exhaustion_limit", 0))
	exhaustion_input.value = float(_get_editor_limit_value(str(enemy.get("category", "monster")), loaded_exhaustion_limit, loaded_attempt_limit))
	_select_equipment_slot(str(enemy.get("equipment_slot", "")))
	weapon_attack_count_input.value = float(enemy.get("weapon_attack_count", _count_icons(enemy.get("granted_icons", []), "spada")))
	attack_bonus_input.value = float(enemy.get("weapon_damage_per_hit", int(enemy.get("attack_bonus", 0)) + 1 if int(enemy.get("attack_bonus", 0)) > 0 else 0))
	armor_value_input.value = float(enemy.get("armor_value", 0))
	_select_object_durability(str(enemy.get("granted_durability_mode", "exhaustible")))
	object_uses_input.value = float(enemy.get("granted_remaining_uses", 1))
	_select_activation_cost(str(enemy.get("activation_cost_type", "none")))
	activation_cost_amount_input.value = float(enemy.get("activation_cost_amount", 0))
	var outcome_text = str(enemy.get("failure_text", enemy.get("flee_text", "")))
	flee_text.text = outcome_text
	reward_text.text = str(enemy.get("reward_text", ""))
	if str(enemy.get("category", "monster")) == "treasure":
		var success_lines = _join_outcome_lines(enemy.get("success_outcomes", []))
		var failure_lines = _join_outcome_lines(enemy.get("failure_outcomes", []))
		if not success_lines.is_empty():
			reward_text.text = success_lines
		if not failure_lines.is_empty():
			flee_text.text = failure_lines
	pending_image_source_path = ""
	pending_image_project_path = ""
	_update_preview_from_project(image_path_input.text)
	_load_sequence(enemy.get("requirements", []))
	_load_object_icon_sequence(enemy.get("granted_icons", enemy.get("requirements", [])))
	_update_form_for_category()
	_update_preview()

func _clear_form():
	name_input.text = ""
	image_path_input.text = ""
	_select_category("monster")
	damage_input.value = 1
	attack_sequences_text.text = "spada"
	exhaustion_input.value = 0
	_select_equipment_slot("weapon")
	attack_bonus_input.value = 0
	weapon_attack_count_input.value = 1
	armor_value_input.value = 0
	_select_object_durability("exhaustible")
	object_uses_input.value = 3
	_select_activation_cost("none")
	activation_cost_amount_input.value = 0
	flee_text.text = ""
	reward_text.text = ""
	pending_image_source_path = ""
	pending_image_project_path = ""
	enemy_preview.texture = null
	_clear_children_now(sequence_slots)
	_add_sequence_slot()
	_clear_children_now(object_icons_slots)
	_add_object_icon_slot()
	_update_form_for_category()
	_update_preview()

func _load_sequence(requirements):
	_clear_children_now(sequence_slots)
	for requirement in requirements:
		var slot = _create_slot()
		slot.custom_minimum_size = Vector2(78, 78)
		sequence_slots.add_child(slot)
		var icon_id = str(requirement)
		var texture_path = _get_icon_path(icon_id)
		if texture_path.is_empty():
			continue
		var token = TextureRect.new()
		token.set_script(REQUIREMENT_TOKEN_SCRIPT)
		token.call("setup", icon_id, texture_path, false)
		slot.call("place_token", token)
	if sequence_slots.get_child_count() == 0:
		_add_sequence_slot()

func _get_sequence_data():
	var sequence: Array = []
	for slot in sequence_slots.get_children():
		if slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token")
			if token != null:
				sequence.append(str(token.get("icon_id")))
	return sequence

func _load_object_icon_sequence(requirements):
	_clear_children_now(object_icons_slots)
	for requirement in requirements:
		var slot = _create_slot()
		slot.custom_minimum_size = Vector2(78, 78)
		object_icons_slots.add_child(slot)
		var icon_id = str(requirement)
		var texture_path = _get_icon_path(icon_id)
		if texture_path.is_empty():
			continue
		var token = TextureRect.new()
		token.set_script(REQUIREMENT_TOKEN_SCRIPT)
		token.call("setup", icon_id, texture_path, false)
		slot.call("place_token", token)
	if object_icons_slots.get_child_count() == 0:
		_add_object_icon_slot()

func _get_object_icon_sequence_data() -> Array:
	var sequence: Array = []
	for slot in object_icons_slots.get_children():
		if slot.has_method("has_token") and slot.call("has_token"):
			var token = slot.call("get_token")
			if token != null:
				sequence.append(str(token.get("icon_id")))
	return sequence

func _update_preview():
	preview_name.text = name_input.text if not name_input.text.is_empty() else "Nome Carta"
	card_name.text = preview_name.text
	var requirements = _get_sequence_data()
	var category_id = _get_selected_category_id()
	difficulty_value.text = "%d icone" % requirements.size()
	preview_requirement_title.text = _get_requirement_title(category_id)
	if _uses_damage(category_id) and int(damage_input.value) > 0:
		preview_meta_line.visible = true
		var attacks = _parse_attack_sequences(attack_sequences_text.text)
		var sequence_text = ""
		if not attacks.is_empty():
			sequence_text = " | Sequenze: %d" % attacks.size()
		preview_meta_line.text = "Danno/attacco: %d%s" % [int(damage_input.value), sequence_text]
	else:
		preview_meta_line.visible = false
		preview_meta_line.text = ""
	if category_id == "object":
		preview_meta_line.visible = true
		preview_meta_line.text = _get_object_preview_meta()
	preview_exhaustion_line.visible = false
	preview_flee_line.visible = false
	preview_reward_line.visible = false
	preview_exhaustion_line.text = ""
	preview_flee_line.text = ""
	preview_reward_line.text = ""
	_clear_children_now(preview_requirement_row)
	for icon_id in requirements:
		var texture_path = _get_icon_path(icon_id)
		if texture_path.is_empty():
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(42, 42)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(texture_path):
			icon.texture = load(texture_path)
		icon.tooltip_text = icon_id.capitalize()
		preview_requirement_row.add_child(icon)

func _update_preview_from_project(project_path):
	if project_path.is_empty():
		enemy_preview.texture = null
		return
	if ResourceLoader.exists(project_path):
		enemy_preview.texture = load(project_path)
		return
	var absolute_path = ProjectSettings.globalize_path(project_path)
	var image := Image.new()
	if image.load(absolute_path) == OK:
		enemy_preview.texture = ImageTexture.create_from_image(image)
		return
	enemy_preview.texture = null

func _update_preview_from_absolute(abs_path):
	var image := Image.new()
	if image.load(abs_path) != OK:
		enemy_preview.texture = null
		return
	enemy_preview.texture = ImageTexture.create_from_image(image)

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

func _normalize_enemy_record(enemy):
	var enemy_name := str(enemy.get("name", "Carta senza nome"))
	var image_path := str(enemy.get("image", ""))
	var category_id = _normalize_category(str(enemy.get("category", "monster")))
	var requirements: Array = []
	var raw_requirements = enemy.get("requirements", [])
	if raw_requirements is Array:
		for requirement in raw_requirements:
			var requirement_id = str(requirement)
			requirements.append(requirement_id)
	var damage_default = 1 if category_id == "monster" else 0
	var enemy_damage = int(enemy.get("enemy_damage", damage_default))
	var attack_sequences = _normalize_attack_sequences(enemy.get("attack_sequences", []))
	if not _uses_damage(category_id):
		attack_sequences = []
	var exhaustion_limit = int(enemy.get("exhaustion_limit", 0))
	var attempt_limit = int(enemy.get("attempt_limit", 0))
	var flee_value := str(enemy.get("failure_text", enemy.get("flee_text", "")))
	var reward_value = enemy.get("reward_text", "")
	if reward_value == "" and enemy.has("reward"):
		reward_value = str(enemy.get("reward"))
	var flee_effects = enemy.get("flee_effects", EffectTextParser.parse_enemy_flee_effects(flee_value))
	var reward_effects = enemy.get("reward_effects", EffectTextParser.parse_enemy_reward_effects(str(reward_value)))
	var difficulty = int(enemy.get("difficulty", requirements.size()))
	var equipment_slot = _normalize_equipment_slot(str(enemy.get("equipment_slot", "")))
	var attack_bonus = int(enemy.get("attack_bonus", 0))
	var weapon_damage_per_hit = int(enemy.get("weapon_damage_per_hit", attack_bonus + 1 if attack_bonus > 0 else 0))
	var armor_value = int(enemy.get("armor_value", 0))
	var granted_icons: Array = []
	var raw_granted_icons = enemy.get("granted_icons", enemy.get("requirements", []))
	if raw_granted_icons is Array:
		for requirement in raw_granted_icons:
			var granted_id = str(requirement)
			if not granted_id.is_empty():
				granted_icons.append(granted_id)
	var granted_durability_mode = _normalize_object_durability(str(enemy.get("granted_durability_mode", "exhaustible")))
	var granted_remaining_uses = max(1, int(enemy.get("granted_remaining_uses", 1)))
	var activation_cost_type = _normalize_activation_cost(str(enemy.get("activation_cost_type", "none")))
	var activation_cost_amount = max(0, int(enemy.get("activation_cost_amount", 0)))
	var weapon_attack_count = int(enemy.get("weapon_attack_count", _count_icons(granted_icons, "spada")))
	var success_outcomes: Array = []
	var raw_success_outcomes = enemy.get("success_outcomes", [])
	if raw_success_outcomes is Array:
		for entry in raw_success_outcomes:
			success_outcomes.append(str(entry))
	var failure_outcomes: Array = []
	var raw_failure_outcomes = enemy.get("failure_outcomes", [])
	if raw_failure_outcomes is Array:
		for entry in raw_failure_outcomes:
			failure_outcomes.append(str(entry))
	return {
		"id": str(enemy.get("id", _slugify(enemy_name))),
		"name": enemy_name,
		"image": image_path,
		"category": category_id,
		"enemy_damage": enemy_damage,
		"attack_sequences": attack_sequences,
		"exhaustion_limit": exhaustion_limit,
		"attempt_limit": attempt_limit,
		"difficulty": difficulty,
		"requirements": requirements,
		"flee_text": flee_value,
		"failure_text": flee_value,
		"flee_effects": flee_effects,
		"failure_effects": flee_effects,
		"reward_text": str(reward_value),
		"reward_effects": reward_effects,
		"success_outcomes": success_outcomes,
		"failure_outcomes": failure_outcomes,
		"equipment_slot": equipment_slot,
		"attack_bonus": attack_bonus,
		"weapon_attack_count": weapon_attack_count,
		"weapon_damage_per_hit": weapon_damage_per_hit,
		"armor_value": armor_value,
		"granted_icons": granted_icons,
		"granted_durability_mode": granted_durability_mode,
		"granted_remaining_uses": granted_remaining_uses,
		"activation_cost_type": activation_cost_type,
		"activation_cost_amount": activation_cost_amount
	}

func _create_slot():
	var slot = PanelContainer.new()
	slot.set_script(REQUIREMENT_SLOT_SCRIPT)
	slot.set_meta("editor_module", self)
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

func notify_requirement_slot_changed():
	_update_preview()

func _get_icon_path(icon_id):
	for icon_data in _get_available_icon_palette():
		if str(icon_data["id"]) == icon_id:
			return str(icon_data["path"])
	return ""

func _get_available_icon_palette():
	var all_icons: Array = []
	for icon_data in DICE_ICON_PALETTE:
		all_icons.append(icon_data)
	for icon_data in ITEM_ICON_PALETTE:
		all_icons.append(icon_data)
	return all_icons

func _get_selected_category_id():
	var selected = category_input.selected
	if selected < 0 or selected >= CATEGORY_OPTIONS.size():
		return "monster"
	return str(CATEGORY_OPTIONS[selected]["id"])

func _select_category(category_id):
	var normalized = _normalize_category(category_id)
	for index in range(CATEGORY_OPTIONS.size()):
		if str(CATEGORY_OPTIONS[index]["id"]) == normalized:
			category_input.select(index)
			return
	category_input.select(0)

func _normalize_category(category_id):
	for option in CATEGORY_OPTIONS:
		if str(option["id"]) == category_id:
			return category_id
	return "monster"

func _get_selected_equipment_slot_id():
	var selected = equipment_slot_input.selected
	if selected < 0 or selected >= EQUIPMENT_SLOT_OPTIONS.size():
		return "weapon"
	return str(EQUIPMENT_SLOT_OPTIONS[selected]["id"])

func _get_selected_object_durability_id():
	var selected = object_durability_input.selected
	if selected < 0 or selected >= DURABILITY_OPTIONS.size():
		return "exhaustible"
	return str(DURABILITY_OPTIONS[selected]["id"])

func _get_selected_activation_cost_id():
	var selected = activation_cost_input.selected
	if selected < 0 or selected >= ACTIVATION_COST_OPTIONS.size():
		return "none"
	return str(ACTIVATION_COST_OPTIONS[selected]["id"])

func _select_equipment_slot(slot_id):
	var normalized = _normalize_equipment_slot(slot_id)
	for index in range(EQUIPMENT_SLOT_OPTIONS.size()):
		if str(EQUIPMENT_SLOT_OPTIONS[index]["id"]) == normalized:
			equipment_slot_input.select(index)
			return
	equipment_slot_input.select(0)

func _select_object_durability(durability_id):
	var normalized = _normalize_object_durability(durability_id)
	for index in range(DURABILITY_OPTIONS.size()):
		if str(DURABILITY_OPTIONS[index]["id"]) == normalized:
			object_durability_input.select(index)
			return
	object_durability_input.select(0)

func _select_activation_cost(cost_id):
	var normalized = _normalize_activation_cost(cost_id)
	for index in range(ACTIVATION_COST_OPTIONS.size()):
		if str(ACTIVATION_COST_OPTIONS[index]["id"]) == normalized:
			activation_cost_input.select(index)
			return
	activation_cost_input.select(0)

func _normalize_equipment_slot(slot_id):
	for option in EQUIPMENT_SLOT_OPTIONS:
		if str(option["id"]) == slot_id:
			return slot_id
	return "weapon"

func _normalize_object_durability(durability_id):
	for option in DURABILITY_OPTIONS:
		if str(option["id"]) == durability_id:
			return durability_id
	return "exhaustible"

func _normalize_activation_cost(cost_id):
	for option in ACTIVATION_COST_OPTIONS:
		if str(option["id"]) == cost_id:
			return cost_id
	return "none"

func _get_object_durability_label(durability_id):
	var normalized = _normalize_object_durability(durability_id)
	for option in DURABILITY_OPTIONS:
		if str(option["id"]) == normalized:
			return str(option["label"])
	return "Esauribile"

func _get_activation_cost_label(cost_id):
	var normalized = _normalize_activation_cost(cost_id)
	for option in ACTIVATION_COST_OPTIONS:
		if str(option["id"]) == normalized:
			return str(option["label"])
	return "Nessuno"

func _get_equipment_slot_label(slot_id):
	var normalized = _normalize_equipment_slot(slot_id)
	for option in EQUIPMENT_SLOT_OPTIONS:
		if str(option["id"]) == normalized:
			return str(option["label"])
	return "Arma"

func _get_category_label(category_id):
	var normalized = _normalize_category(category_id)
	for option in CATEGORY_OPTIONS:
		if str(option["id"]) == normalized:
			return str(option["label"])
	return "Mostro"

func _get_exhaustion_preview_text(category_id, exhaustion_limit):
	if _uses_attempt_limit(category_id):
		if int(exhaustion_limit) <= 0:
			return "Tentativi: Illimitati"
		return "Tentativi: Dopo %d fallimenti la carta viene rimossa" % int(exhaustion_limit)
	if int(exhaustion_limit) <= 0:
		return "Esaurimento: Permanente"
	return "Esaurimento: Risolta dopo %d affronti" % int(exhaustion_limit)

func _update_form_for_category():
	var category_id = _get_selected_category_id()
	damage_label.visible = _uses_damage(category_id)
	damage_input.visible = _uses_damage(category_id)
	attack_sequences_label.visible = _uses_damage(category_id)
	attack_sequences_text.visible = _uses_damage(category_id)
	exhaustion_label.text = _get_limit_label(category_id)
	flee_label.text = _get_outcome_label(category_id)
	reward_label.text = _get_reward_label(category_id)
	var is_treasure = category_id == "treasure"
	var is_object = category_id == "object"
	var is_weapon = is_object and _get_selected_equipment_slot_id() == "weapon"
	var is_armor = is_object and _get_selected_equipment_slot_id() == "armor"
	flee_label.visible = true
	flee_text.visible = true
	reward_label.visible = true
	reward_text.visible = true
	equipment_slot_label.visible = is_object
	equipment_slot_input.visible = is_object
	attack_bonus_label.visible = is_weapon
	attack_bonus_input.visible = is_weapon
	weapon_attack_count_label.visible = is_weapon
	weapon_attack_count_input.visible = is_weapon
	armor_value_label.visible = is_armor
	armor_value_input.visible = is_armor
	var show_manual_icons = is_object and not is_weapon
	object_icons_label.visible = show_manual_icons
	object_icons_palette.visible = show_manual_icons
	object_icons_buttons.visible = show_manual_icons
	object_icons_slots.visible = show_manual_icons
	object_durability_label.visible = is_object
	object_durability_input.visible = is_object
	object_uses_label.visible = is_object
	object_uses_input.visible = is_object
	activation_cost_label.visible = is_object
	activation_cost_input.visible = is_object
	activation_cost_amount_label.visible = is_object
	activation_cost_amount_input.visible = is_object
	attack_bonus_label.text = "Danno Per Colpo"
	armor_value_label.text = "Assorbimento Armatura"
	if is_treasure:
		flee_label.text = "Esiti Possibili Di Fallimento"
		reward_label.text = "Esiti Possibili Di Successo"
	if is_object:
		damage_label.visible = false
		damage_input.visible = false
		attack_sequences_label.visible = false
		attack_sequences_text.visible = false
		exhaustion_label.text = "Durata Carta"
		flee_label.text = "Testo Se Non Recuperato"
		reward_label.text = "Testo Equipaggiamento"
		weapon_attack_count_input.editable = is_weapon
		attack_bonus_input.editable = is_weapon
		armor_value_input.editable = _get_selected_equipment_slot_id() == "armor"
		object_uses_input.editable = _get_selected_object_durability_id() == "ephemeral"
		activation_cost_amount_input.editable = _get_selected_activation_cost_id() != "none"
		if not weapon_attack_count_input.editable:
			weapon_attack_count_input.value = 0
		if not attack_bonus_input.editable:
			attack_bonus_input.value = 0
		if not armor_value_input.editable:
			armor_value_input.value = 0
		if not object_uses_input.editable:
			object_uses_input.value = 1
		if not activation_cost_amount_input.editable:
			activation_cost_amount_input.value = 0

func _uses_damage(category_id):
	return category_id == "monster" or category_id == "trap"

func _parse_attack_sequences(source_text: String) -> Array:
	var sequences: Array = []
	for raw_line in source_text.split("\n"):
		var line = str(raw_line).strip_edges().to_lower()
		if line.is_empty():
			continue
		line = line.replace(",", " ")
		line = line.replace(";", " ")
		var sequence: Array = []
		for raw_token in line.split(" ", false):
			var token = _normalize_attack_token(str(raw_token))
			if not token.is_empty():
				sequence.append(token)
		if not sequence.is_empty():
			sequences.append(sequence)
	return sequences

func _normalize_attack_sequences(raw_sequences) -> Array:
	var sequences: Array = []
	if not (raw_sequences is Array):
		return sequences
	for raw_sequence in raw_sequences:
		var sequence: Array = []
		if raw_sequence is Array:
			for raw_token in raw_sequence:
				var token = _normalize_attack_token(str(raw_token))
				if not token.is_empty():
					sequence.append(token)
		elif raw_sequence is String:
			for parsed_sequence in _parse_attack_sequences(str(raw_sequence)):
				sequences.append(parsed_sequence)
		if not sequence.is_empty():
			sequences.append(sequence)
	return sequences

func _join_attack_sequences(raw_sequences) -> String:
	var lines: Array[String] = []
	for sequence in _normalize_attack_sequences(raw_sequences):
		lines.append(", ".join(sequence))
	return "\n".join(lines)

func _normalize_attack_token(token: String) -> String:
	var normalized = token.strip_edges().to_lower()
	if normalized == "attacco" or normalized == "attacca" or normalized == "attack":
		return "spada"
	if normalized == "para" or normalized == "parata" or normalized == "blocco" or normalized == "block":
		return "scudo"
	if normalized == "spada" or normalized == "scudo":
		return normalized
	return ""

func _uses_attempt_limit(category_id):
	return category_id == "treasure" or category_id == "door" or category_id == "event"

func _get_limit_label(category_id):
	if _uses_attempt_limit(category_id):
		return "Tentativi Prima Del Fallimento"
	return "Esaurimento Carta"

func _get_requirement_title(category_id):
	if category_id == "treasure":
		return "Per Aprire"
	if category_id == "door":
		return "Per Aprire"
	if category_id == "event":
		return "Per Risolvere"
	if category_id == "stairs":
		return "Per Attivare"
	if category_id == "object":
		return "Per Recuperare"
	return "Per Sconfiggere"

func _get_outcome_label(category_id):
	if category_id == "treasure":
		return "Testo Fallimento Apertura"
	if category_id == "door":
		return "Testo Fallimento Apertura"
	if category_id == "event":
		return "Testo Fallimento Evento"
	if category_id == "trap":
		return "Testo Fallimento"
	if category_id == "stairs":
		return "Testo Mancata Attivazione"
	if category_id == "object":
		return "Testo Mancato Recupero"
	return "Testo Fuga"

func _get_outcome_prefix(category_id):
	if category_id == "treasure":
		return "Fallimento"
	if category_id == "door":
		return "Fallimento"
	if category_id == "event":
		return "Fallimento"
	if category_id == "trap":
		return "Fallimento"
	if category_id == "stairs":
		return "Mancata attivazione"
	return "Fuga"

func _get_reward_label(category_id):
	if category_id == "stairs":
		return "Effetto Successo"
	if category_id == "object":
		return "Testo Oggetto Equipaggiato"
	return "Testo Premio"

func _get_object_preview_meta():
	var slot_id = _get_selected_equipment_slot_id()
	var parts: Array[String] = ["Slot: %s" % _get_equipment_slot_label(slot_id)]
	var granted_icons = _build_weapon_attack_icons(int(weapon_attack_count_input.value)) if slot_id == "weapon" else _get_object_icon_sequence_data()
	if not granted_icons.is_empty():
		parts.append("Icone: %s" % ", ".join(granted_icons))
	var durability_id = _get_selected_object_durability_id()
	if durability_id == "ephemeral":
		parts.append("%s %d usi" % [_get_object_durability_label(durability_id), int(object_uses_input.value)])
	else:
		parts.append(_get_object_durability_label(durability_id))
	var cost_id = _get_selected_activation_cost_id()
	if cost_id != "none" and int(activation_cost_amount_input.value) > 0:
		parts.append("Costo: %d %s" % [int(activation_cost_amount_input.value), _get_activation_cost_label(cost_id)])
	if slot_id == "weapon" and int(attack_bonus_input.value) > 0:
		parts.append("Danno/colpo %d" % int(attack_bonus_input.value))
	if int(armor_value_input.value) > 0:
		parts.append("Armatura %d" % int(armor_value_input.value))
	if parts.size() == 1:
		parts.append("Nessun bonus")
	return " | ".join(parts)

func _on_object_durability_changed(_index):
	_update_form_for_category()
	_update_preview()

func _on_object_uses_changed(_value):
	_update_preview()

func _build_weapon_attack_icons(count: int) -> Array:
	var icons: Array = []
	for _i in max(0, count):
		icons.append("spada")
	return icons

func _count_icons(icons, icon_id: String) -> int:
	var count := 0
	if not (icons is Array):
		return count
	for raw_icon in icons:
		if str(raw_icon) == icon_id:
			count += 1
	return count

func _get_reward_prefix(category_id):
	if category_id == "stairs":
		return "Successo"
	return "Premio"

func _get_attempt_limit_for_category():
	var category_id = _get_selected_category_id()
	if _uses_attempt_limit(category_id):
		return int(exhaustion_input.value)
	return 0

func _get_editor_limit_value(category_id, exhaustion_limit, attempt_limit):
	if _uses_attempt_limit(category_id):
		return attempt_limit
	return exhaustion_limit

func _parse_outcome_lines(source_text):
	var outcomes: Array = []
	for line in str(source_text).split("\n"):
		var cleaned = line.strip_edges()
		if cleaned.is_empty():
			continue
		outcomes.append(cleaned)
	return outcomes

func _join_outcome_lines(outcomes):
	if not (outcomes is Array):
		return ""
	var lines: Array = []
	for outcome in outcomes:
		lines.append(str(outcome))
	return "\n".join(lines)

func _set_status(message):
	status_label.text = message

func _clear_children_now(node):
	for child in node.get_children():
		node.remove_child(child)
		child.free()
