extends PanelContainer

var _content: CenterContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_ensure_content()

func _ensure_content() -> void:
	_content = get_node_or_null("Content") as CenterContainer
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
	return data is Dictionary and data.get("type", "") == "result_token"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	var token: Control = data.get("token") as Control
	if token == null:
		return
	var origin_slot: Variant = null
	if token.has_method("get_slot"):
		origin_slot = token.call("get_slot")
	if origin_slot == self:
		return
	var existing_token: Control = get_token()
	if existing_token != null and origin_slot != null and origin_slot.has_method("place_token"):
		origin_slot.call("place_token", existing_token)
	place_token(token)
