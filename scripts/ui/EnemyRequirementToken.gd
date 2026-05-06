extends TextureRect

var icon_id := ""
var texture_path := ""
var _slot = null
var is_palette_token := false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(64, 64)

func setup(p_icon_id, p_texture_path, p_is_palette_token := false):
	icon_id = p_icon_id
	texture_path = p_texture_path
	is_palette_token = p_is_palette_token
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		texture = load(texture_path)
	tooltip_text = icon_id.capitalize()

func set_slot(slot):
	_slot = slot

func get_slot():
	return _slot

func _get_drag_data(_at_position):
	if texture == null:
		return null
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = custom_minimum_size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {
		"type": "enemy_requirement_token",
		"token": self,
		"icon_id": icon_id,
		"texture_path": texture_path,
		"is_palette_token": is_palette_token
	}
