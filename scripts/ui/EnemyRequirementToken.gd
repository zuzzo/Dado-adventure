extends TextureRect

const DURABILITY_BACKGROUND_PATHS := {
	"perennial": "res://assets/icone/ferro.png",
	"exhaustible": "res://assets/icone/legno.png",
	"ephemeral": "res://assets/icone/carta.png"
}

var icon_id := ""
var texture_path := ""
var _slot = null
var is_palette_token := false
var background_mode := ""
var _icon_rect: TextureRect

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(64, 64)
	_ensure_icon_rect()

func setup(p_icon_id, p_texture_path, p_is_palette_token := false, p_background_mode := ""):
	icon_id = p_icon_id
	texture_path = p_texture_path
	is_palette_token = p_is_palette_token
	background_mode = str(p_background_mode)
	_refresh_visuals()
	tooltip_text = icon_id.capitalize()

func set_background_mode(mode: String) -> void:
	background_mode = mode
	_refresh_visuals()

func set_slot(slot):
	_slot = slot

func get_slot():
	return _slot

func _get_drag_data(_at_position):
	if _icon_rect == null or _icon_rect.texture == null:
		return null
	var preview := Control.new()
	preview.custom_minimum_size = custom_minimum_size
	preview.size = custom_minimum_size
	var preview_background := TextureRect.new()
	preview_background.texture = texture
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
		"type": "enemy_requirement_token",
		"token": self,
		"icon_id": icon_id,
		"texture_path": texture_path,
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

func _refresh_visuals() -> void:
	_ensure_icon_rect()
	texture = _load_background_texture()
	_icon_rect.texture = _load_icon_texture()

func _load_icon_texture() -> Texture2D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path)

func _load_background_texture() -> Texture2D:
	if is_palette_token or background_mode.is_empty():
		return null
	var background_path = str(DURABILITY_BACKGROUND_PATHS.get(background_mode, ""))
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return null
	return load(background_path)
