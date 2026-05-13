extends TextureRect

const DURABILITY_BACKGROUND_PATHS := {
	"perennial": "res://assets/icone/ferro.png",
	"exhaustible": "res://assets/icone/legno.png",
	"ephemeral": "res://assets/icone/carta.png"
}

var result_data: Dictionary = {}
var _slot: Control
var _is_exhausted := false
var _disabled_by_cost := false
var _text_label: Label
var _board_interaction_enabled: bool = false
var _icon_rect: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(84, 84)
	_ensure_icon_rect()
	_ensure_text_label()

func setup(data: Dictionary) -> void:
	result_data = data.duplicate(true)
	_ensure_defaults()
	_refresh_display()

func _refresh_display() -> void:
	_ensure_icon_rect()
	_ensure_text_label()
	texture = _load_background_texture(get_durability_mode())
	_icon_rect.texture = result_data.get("symbol_texture") as Texture2D
	tooltip_text = _build_tooltip_text()
	_text_label.text = _build_visible_text()
	_text_label.visible = true
	modulate = _get_display_modulate()

func set_slot(slot: Control) -> void:
	_slot = slot

func get_slot() -> Control:
	return _slot

func get_result_data() -> Dictionary:
	return result_data.duplicate(true)

func set_exhausted(value: bool) -> void:
	_is_exhausted = value
	modulate = _get_display_modulate()

func set_disabled_by_cost(value: bool) -> void:
	_disabled_by_cost = value
	_refresh_display()

func set_result_data_value(key: String, value: Variant) -> void:
	result_data[key] = value
	_ensure_defaults()
	_refresh_display()

func set_board_interaction_enabled(value: bool) -> void:
	_board_interaction_enabled = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE if value else Control.MOUSE_FILTER_PASS

func is_exhausted() -> bool:
	return _is_exhausted

func get_durability_mode() -> String:
	return str(result_data.get("durability_mode", "exhaustible"))

func get_remaining_uses() -> int:
	return int(result_data.get("remaining_uses", 1))

func can_be_used() -> bool:
	if _disabled_by_cost:
		return false
	var durability_mode = get_durability_mode()
	if durability_mode == "ephemeral":
		return get_remaining_uses() > 0
	if durability_mode == "exhaustible":
		return not _is_exhausted
	return true

func consume_use() -> Dictionary:
	var snapshot = get_result_data()
	var durability_mode = get_durability_mode()
	match durability_mode:
		"ephemeral":
			var remaining = max(get_remaining_uses() - 1, 0)
			result_data["remaining_uses"] = remaining
			result_data["value"] = remaining
			if remaining <= 0:
				result_data["label"] = str(result_data.get("base_label", result_data.get("label", "")))
			else:
				result_data["label"] = _build_value_label(remaining)
		"exhaustible":
			set_exhausted(true)
		"perennial":
			pass
	_refresh_display()
	return snapshot

func should_be_removed_after_use() -> bool:
	return get_durability_mode() == "ephemeral" and get_remaining_uses() <= 0

func _get_drag_data(_at_position: Vector2) -> Variant:
	if _board_interaction_enabled:
		return null
	if not can_be_used():
		return null
	if texture == null and (_icon_rect == null or _icon_rect.texture == null):
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
	preview_icon.texture = _icon_rect.texture if _icon_rect != null else null
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_icon.offset_left = 12.0
	preview_icon.offset_top = 12.0
	preview_icon.offset_right = -12.0
	preview_icon.offset_bottom = -12.0
	preview.add_child(preview_icon)
	set_drag_preview(preview)
	return {
		"type": "result_token",
		"token": self
	}

func _ensure_defaults() -> void:
	if not result_data.has("durability_mode"):
		result_data["durability_mode"] = "exhaustible"
	if not result_data.has("base_label"):
		result_data["base_label"] = str(result_data.get("label", ""))
	if not result_data.has("remaining_uses"):
		result_data["remaining_uses"] = int(result_data.get("value", 1))

func _build_tooltip_text() -> String:
	var parts: Array[String] = [str(result_data.get("label", ""))]
	match get_durability_mode():
		"ephemeral":
			parts.append("Effimera: %d usi" % get_remaining_uses())
		"perennial":
			parts.append("Perenne")
		_:
			parts.append("Esauribile")
	var cost_type = str(result_data.get("activation_cost_type", "none"))
	var cost_amount = int(result_data.get("activation_cost_amount", 0))
	if cost_type == "mana" and cost_amount > 0:
		parts.append("Costo: %d mana" % cost_amount)
		if _disabled_by_cost:
			parts.append("Mana insufficiente")
	return " | ".join(parts)

func _get_display_modulate() -> Color:
	if _disabled_by_cost:
		return Color(0.42, 0.42, 0.42, 0.75)
	if _is_exhausted:
		return Color(0.55, 0.55, 0.55, 1)
	if get_durability_mode() == "perennial":
		return Color(1, 1, 1, 1)
	if get_durability_mode() == "ephemeral":
		var alpha = 0.65 + min(float(get_remaining_uses()) / 6.0, 0.35)
		return Color(1, 1, 1, alpha)
	return Color(1, 1, 1, 1)

func _build_value_label(value: int) -> String:
	var symbol_id = str(result_data.get("symbol_id", "")).strip_edges()
	if symbol_id.is_empty():
		return str(result_data.get("base_label", result_data.get("label", "")))
	return "%d %s" % [value, symbol_id]

func _build_visible_text() -> String:
	var symbol_id = str(result_data.get("symbol_id", "")).strip_edges()
	if symbol_id == "+1" or symbol_id == "x2":
		return symbol_id
	if _icon_rect == null or _icon_rect.texture == null:
		return symbol_id if not symbol_id.is_empty() else str(result_data.get("label", ""))
	if get_durability_mode() == "ephemeral":
		return str(get_remaining_uses())
	return ""

func _ensure_text_label() -> void:
	if _text_label != null:
		return
	_text_label = get_node_or_null("TextLabel") as Label
	if _text_label != null:
		return
	_text_label = Label.new()
	_text_label.name = "TextLabel"
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_text_label.add_theme_constant_override("outline_size", 3)
	_text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_child(_text_label)

func _ensure_icon_rect() -> void:
	if _icon_rect != null:
		return
	_icon_rect = get_node_or_null("IconRect") as TextureRect
	if _icon_rect != null:
		return
	_icon_rect = TextureRect.new()
	_icon_rect.name = "IconRect"
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon_rect.offset_left = 12.0
	_icon_rect.offset_top = 12.0
	_icon_rect.offset_right = -12.0
	_icon_rect.offset_bottom = -12.0
	add_child(_icon_rect)

func _load_background_texture(durability_mode: String) -> Texture2D:
	var background_path = str(DURABILITY_BACKGROUND_PATHS.get(durability_mode, DURABILITY_BACKGROUND_PATHS["exhaustible"]))
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return null
	return load(background_path)
