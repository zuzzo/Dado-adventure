extends RigidBody3D

const FACE_SYMBOL_SHADER := preload("res://shaders/dice_face_symbol.gdshader")
const FACE_LAYOUT := [
	{"node_path": NodePath("FaceTop"), "face_id": 2, "local_normal": Vector3(0, 1, 0)},
	{"node_path": NodePath("FaceBottom"), "face_id": 6, "local_normal": Vector3(0, -1, 0)},
	{"node_path": NodePath("FaceFront"), "face_id": 5, "local_normal": Vector3(0, 0, 1)},
	{"node_path": NodePath("FaceBack"), "face_id": 1, "local_normal": Vector3(0, 0, -1)},
	{"node_path": NodePath("FaceRight"), "face_id": 3, "local_normal": Vector3(1, 0, 0)},
	{"node_path": NodePath("FaceLeft"), "face_id": 4, "local_normal": Vector3(-1, 0, 0)},
]

var _faces: Array = []
@onready var hit_sound: AudioStreamPlayer3D = $HitSound
var _last_hit_time_ms: int = 0
const HIT_COOLDOWN_MS := 120
@export var definition: DiceDefinition
var dice_type: String = ""

const DICE_COLORS := {
	"blue": Color(0.35, 0.65, 1.0, 1.0),
	"green": Color(0.3, 0.95, 0.45, 1.0),
	"red": Color(1.0, 0.35, 0.35, 1.0)
}

func _ready() -> void:
	_build_faces()
	if dice_type.is_empty() and definition != null:
		dice_type = definition.default_dice_type
	_apply_dice_color()
	body_entered.connect(_on_body_entered)

func set_dice_type(value: String) -> void:
	dice_type = value
	_apply_dice_color()

func get_dice_type() -> String:
	return dice_type

func _build_faces() -> void:
	_faces.clear()
	for layout in FACE_LAYOUT:
		var node := get_node_or_null(layout["node_path"]) as MeshInstance3D
		if node == null:
			continue
		var face_id := int(layout["face_id"])
		var face_definition := _get_face_definition(face_id)
		_faces.append({
			"node": node,
			"face_id": face_id,
			"value": _get_face_value(face_definition),
			"label": _get_face_label(face_definition, face_id),
			"symbol_texture": _get_face_texture(face_definition),
			"local_normal": layout["local_normal"]
		})

func _apply_dice_color() -> void:
	var tint: Color = DICE_COLORS.get(dice_type, DICE_COLORS.get("red", Color.WHITE))
	for entry in _faces:
		var node := entry["node"] as MeshInstance3D
		if node == null:
			continue
		var symbol_texture := entry["symbol_texture"] as Texture2D
		if symbol_texture != null:
			node.material_override = _create_symbol_material(tint, symbol_texture)
		else:
			node.material_override = _create_base_material(tint)

func _create_base_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	return mat

func _create_symbol_material(tint: Color, symbol_texture: Texture2D) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FACE_SYMBOL_SHADER
	mat.set_shader_parameter("base_color", tint)
	mat.set_shader_parameter("symbol_texture", symbol_texture)
	mat.set_shader_parameter("roughness_value", 1.0)
	return mat

func _get_face_definition(face_id: int) -> DiceFaceDefinition:
	if definition == null:
		return null
	return definition.get_face_definition(face_id)

func _get_face_value(face_definition: DiceFaceDefinition) -> int:
	if face_definition == null:
		return 0
	return face_definition.value

func _get_face_label(face_definition: DiceFaceDefinition, face_id: int) -> String:
	if face_definition == null:
		return str(face_id)
	return face_definition.label

func _get_face_texture(face_definition: DiceFaceDefinition) -> Texture2D:
	if face_definition == null:
		return null
	return face_definition.symbol_texture

func _on_body_entered(body: Node) -> void:
	if body == null or body.name != "Table":
		return
	var now := Time.get_ticks_msec()
	if now - _last_hit_time_ms < HIT_COOLDOWN_MS:
		return
	_last_hit_time_ms = now
	if hit_sound != null:
		hit_sound.play()

func _get_global_normal(face: Dictionary) -> Vector3:
	# Transform local normal to global space using dice rotation
	var local_normal = face["local_normal"]
	var global_normal = transform.basis * local_normal
	return global_normal.normalized()

func get_top_value() -> int:
	var best_dot := -2.0  # dot product range is [-1, 1]
	var best_value := 1
	var best_face_id := 1
	var best_label := ""
	
	# UP vector in world space (positive Y)
	var up = Vector3.UP
	
	for entry in _faces:
		var global_normal = _get_global_normal(entry)
		# dot product tells us how parallel the normal is to UP
		# highest dot product = most "pointing up" = top face
		var dot = global_normal.dot(up)
		if dot > best_dot:
			best_dot = dot
			best_value = entry["value"]
			best_face_id = entry["face_id"]
			best_label = entry["label"]
	
	print("Top face: %d (%s, dot: %.3f)" % [best_face_id, best_label, best_dot])
	return best_value

func get_top_name() -> String:
	var best_dot := -2.0
	var best_name := ""
	var up = Vector3.UP
	
	for entry in _faces:
		var global_normal = _get_global_normal(entry)
		var dot = global_normal.dot(up)
		if dot > best_dot:
			best_dot = dot
			best_name = entry["label"]
	
	return best_name

func get_top_face_id() -> int:
	var best_dot := -2.0
	var best_face_id := 1
	var up := Vector3.UP

	for entry in _faces:
		var global_normal = _get_global_normal(entry)
		var dot = global_normal.dot(up)
		if dot > best_dot:
			best_dot = dot
			best_face_id = int(entry["face_id"])

	return best_face_id
