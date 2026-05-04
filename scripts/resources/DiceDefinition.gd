extends Resource
class_name DiceDefinition

@export var definition_name: String = ""
@export var default_dice_type: String = "red"
@export var faces: Array[DiceFaceDefinition] = []

func get_face_definition(face_id: int) -> DiceFaceDefinition:
	for face in faces:
		if face != null and face.face_id == face_id:
			return face
	return null
