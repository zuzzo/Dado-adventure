extends TextureRect

var result_data: Dictionary = {}
var _slot: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(84, 84)

func setup(data: Dictionary) -> void:
	result_data = data.duplicate(true)
	texture = result_data.get("symbol_texture") as Texture2D
	tooltip_text = str(result_data.get("label", ""))

func set_slot(slot: Control) -> void:
	_slot = slot

func get_slot() -> Control:
	return _slot

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
		"type": "result_token",
		"token": self
	}
