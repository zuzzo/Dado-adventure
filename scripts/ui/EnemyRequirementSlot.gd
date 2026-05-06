extends PanelContainer

var _content = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	_ensure_content()

func _ensure_content():
	_content = get_node_or_null("Content")
	if _content != null:
		return
	_content = CenterContainer.new()
	_content.name = "Content"
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_content)

func has_token():
	return _content != null and _content.get_child_count() > 0

func get_token():
	if not has_token():
		return null
	return _content.get_child(0)

func clear_token():
	var token = get_token()
	if token != null:
		token.queue_free()

func place_token(token):
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

func _can_drop_data(_at_position, data):
	return data is Dictionary and data.get("type", "") == "enemy_requirement_token"

func _drop_data(_at_position, data):
	if not (data is Dictionary):
		return
	var token = data.get("token")
	var icon_id = str(data.get("icon_id", ""))
	var texture_path = str(data.get("texture_path", ""))
	var is_palette_token = bool(data.get("is_palette_token", false))
	var origin_slot = null
	if token != null and token.has_method("get_slot"):
		origin_slot = token.call("get_slot")
	var incoming = token
	if is_palette_token:
		incoming = TextureRect.new()
		incoming.set_script(load("res://scripts/ui/EnemyRequirementToken.gd"))
		incoming.call("setup", icon_id, texture_path, false)
	var existing = get_token()
	if existing != null and origin_slot != null and origin_slot != self and origin_slot.has_method("place_token"):
		origin_slot.call("place_token", existing)
	elif existing != null and (origin_slot == null or origin_slot == self or is_palette_token):
		existing.queue_free()
	place_token(incoming)
