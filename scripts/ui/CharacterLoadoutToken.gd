extends TextureRect

const DURABILITY_BACKGROUND_PATHS := {
	"perennial": "res://assets/icone/ferro.png",
	"exhaustible": "res://assets/icone/legno.png",
	"ephemeral": "res://assets/icone/carta.png"
}

var icon_id: String = ""
var texture_path: String = ""
var config: Dictionary = {}
var is_palette_token: bool = false
var _slot = null
var _editor_module = null
var _icon_rect: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(64, 64)
	_ensure_icon_rect()
	_refresh_visuals()

func setup(p_icon_id: String, p_texture_path: String, p_config: Dictionary, p_editor_module, p_is_palette_token := false) -> void:
	icon_id = p_icon_id
	texture_path = p_texture_path
	config = p_config.duplicate(true)
	is_palette_token = p_is_palette_token
	_editor_module = p_editor_module
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

func _refresh_visuals() -> void:
	if _icon_rect == null:
		return
	var durability_mode: String = str(config.get("durability_mode", "exhaustible"))
	var remaining_uses: int = max(1, int(config.get("remaining_uses", 1)))
	texture = null if is_palette_token else _load_background_texture(durability_mode)
	_icon_rect.texture = _load_icon_texture()
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
	if _icon_rect == null or _icon_rect.texture == null:
		return null
	var preview := Control.new()
	preview.custom_minimum_size = custom_minimum_size
	preview.size = custom_minimum_size
	var preview_background := TextureRect.new()
	preview_background.texture = texture if not is_palette_token else null
	preview_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.add_child(preview_background)
	var preview_icon := TextureRect.new()
	preview_icon.texture = _icon_rect.texture
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_icon.offset_left = 8.0
	preview_icon.offset_top = 8.0
	preview_icon.offset_right = -8.0
	preview_icon.offset_bottom = -8.0
	preview.add_child(preview_icon)
	set_drag_preview(preview)
	return {
		"type": "character_loadout_token",
		"token": self,
		"icon_id": icon_id,
		"texture_path": texture_path,
		"config": get_config(),
		"is_palette_token": is_palette_token
	}

func _ensure_icon_rect() -> void:
	_icon_rect = get_node_or_null("IconRect") as TextureRect
	if _icon_rect != null:
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "IconRect"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon_rect.offset_left = 8.0
	_icon_rect.offset_top = 8.0
	_icon_rect.offset_right = -8.0
	_icon_rect.offset_bottom = -8.0
	add_child(_icon_rect)

func _load_icon_texture() -> Texture2D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path)

func _load_background_texture(durability_mode: String) -> Texture2D:
	var background_path = str(DURABILITY_BACKGROUND_PATHS.get(durability_mode, DURABILITY_BACKGROUND_PATHS["exhaustible"]))
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return null
	return load(background_path)
