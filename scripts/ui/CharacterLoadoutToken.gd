extends TextureRect

var icon_id: String = ""
var texture_path: String = ""
var config: Dictionary = {}
var is_palette_token: bool = false
var _slot = null
var _editor_module = null
var _overlay_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(64, 64)
	_ensure_overlay_label()
	_refresh_visuals()

func setup(p_icon_id: String, p_texture_path: String, p_config: Dictionary, p_editor_module, p_is_palette_token := false) -> void:
	icon_id = p_icon_id
	texture_path = p_texture_path
	config = p_config.duplicate(true)
	is_palette_token = p_is_palette_token
	_editor_module = p_editor_module
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		texture = load(texture_path)
	_ensure_defaults()
	_refresh_visuals()

func set_slot(slot) -> void:
	_slot = slot

func get_slot():
	return _slot

func get_config() -> Dictionary:
	_ensure_defaults()
	return config.duplicate(true)

func set_config(new_config: Dictionary) -> void:
	config = new_config.duplicate(true)
	_ensure_defaults()
	_refresh_visuals()

func _ensure_defaults() -> void:
	if not config.has("symbol_id"):
		config["symbol_id"] = icon_id
	if not config.has("durability_mode"):
		config["durability_mode"] = "exhaustible"
	if not config.has("remaining_uses"):
		config["remaining_uses"] = 1

func _ensure_overlay_label() -> void:
	_overlay_label = get_node_or_null("OverlayLabel") as Label
	if _overlay_label != null:
		return
	_overlay_label = Label.new()
	_overlay_label.name = "OverlayLabel"
	_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_overlay_label.offset_left = -34.0
	_overlay_label.offset_top = -22.0
	_overlay_label.offset_right = -6.0
	_overlay_label.offset_bottom = -4.0
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_overlay_label.add_theme_font_size_override("font_size", 14)
	_overlay_label.add_theme_constant_override("outline_size", 3)
	_overlay_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_overlay_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_child(_overlay_label)

func _refresh_visuals() -> void:
	if _overlay_label == null:
		return
	var durability_mode: String = str(config.get("durability_mode", "exhaustible"))
	var remaining_uses: int = max(1, int(config.get("remaining_uses", 1)))
	var suffix: String = ""
	match durability_mode:
		"ephemeral":
			suffix = "E%d" % remaining_uses
		"perennial":
			suffix = "P"
		_:
			suffix = "R"
	_overlay_label.text = "" if is_palette_token else suffix
	tooltip_text = _build_tooltip(durability_mode, remaining_uses)

func _build_tooltip(durability_mode: String, remaining_uses: int) -> String:
	var mode_label := "Esauribile"
	if durability_mode == "ephemeral":
		mode_label = "Effimera"
	elif durability_mode == "perennial":
		mode_label = "Perenne"
	if durability_mode == "ephemeral":
		return "%s | %s | Usi: %d" % [icon_id.capitalize(), mode_label, remaining_uses]
	return "%s | %s" % [icon_id.capitalize(), mode_label]

func _gui_input(event: InputEvent) -> void:
	if is_palette_token:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _editor_module != null and _editor_module.has_method("open_loadout_token_menu"):
			_editor_module.call("open_loadout_token_menu", self)
			accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if texture == null:
		return null
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = custom_minimum_size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {
		"type": "character_loadout_token",
		"token": self,
		"icon_id": icon_id,
		"texture_path": texture_path,
		"config": get_config(),
		"is_palette_token": is_palette_token
	}
