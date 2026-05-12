extends PanelContainer

var _content = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_ensure_content()

func _ensure_content() -> void:
	_content = get_node_or_null("Content")
	if _content != null:
		return
	_content = CenterContainer.new()
	_content.name = "Content"
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_content)

func has_token() -> bool:
	return _content != null and _content.get_child_count() > 0

func get_token() -> Control:
	if not has_token():
		return null
	return _content.get_child(0) as Control

func clear_token() -> Control:
	var token = get_token()
	if token == null:
		return null
	_content.remove_child(token)
	return token

func place_token(token: Control) -> void:
	if token == null:
		return
	_ensure_content()
	if token.get_parent() == null:
		_content.add_child(token)
	else:
		token.reparent(_content)
	token.position = Vector2.ZERO
	token.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	token.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if token.has_method("set_slot"):
		token.call("set_slot", self)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "character_loadout_token"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	var editor_module = get_meta("editor_module", null)
	var token = data.get("token") as Control
	var incoming = token
	var is_palette_token: bool = bool(data.get("is_palette_token", false))
	if is_palette_token:
		if editor_module == null or not editor_module.has_method("create_loadout_token_instance"):
			return
		incoming = editor_module.call(
			"create_loadout_token_instance",
			str(data.get("icon_id", "")),
			str(data.get("texture_path", "")),
			data.get("config", {})
		)
	if incoming == null:
		return
	var origin_slot = null
	if token != null and token.has_method("get_slot"):
		origin_slot = token.call("get_slot")
	if not is_palette_token and origin_slot != null and origin_slot != self and origin_slot.has_method("clear_token"):
		origin_slot.call("clear_token")
	var existing = clear_token()
	place_token(incoming)
	if existing != null and not is_palette_token and origin_slot != null and origin_slot != self and origin_slot.has_method("place_token"):
		origin_slot.call("place_token", existing)
	elif existing != null:
		existing.queue_free()
	if editor_module != null and editor_module.has_method("notify_loadout_changed"):
		editor_module.call("notify_loadout_changed")
