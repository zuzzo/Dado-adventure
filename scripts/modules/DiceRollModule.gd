extends Node3D

signal roll_completed(results)

@export var dice_scene: PackedScene
@export var dice_scenes: Array = []
@export var max_dice_per_roll: int = 12

var active_dice: Array[RigidBody3D] = []
var next_roll_count: int = 1
var roll_in_progress: bool = false
var forced_roll_scenes: Array = []

const SPAWN_CENTER := Vector3(0.0, 2.2, 0.0)
const SPAWN_RADIUS := 1.35
const SPAWN_HEIGHT_STEP := 0.12
const STABLE_LINEAR_THRESHOLD := 0.05
const STABLE_ANGULAR_THRESHOLD := 0.05
const REQUIRED_STABLE_TIME := 0.35
const MAX_WAIT_SECONDS := 6.0

func _ready() -> void:
	randomize()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_start_roll()

func _start_roll() -> void:
	await _roll_internal(next_roll_count, true)

func roll_dice(count: int) -> void:
	await _roll_internal(count, false)

func set_dice_scenes_for_roll(scenes: Array) -> void:
	forced_roll_scenes = scenes.duplicate()

func _roll_internal(count: int, increment_counter: bool) -> void:
	var available_dice_scenes = _get_available_dice_scenes()
	if roll_in_progress or available_dice_scenes.is_empty():
		return
	_clear_dice()
	roll_in_progress = true

	for i in count:
		var selected_scene = null
		if i < forced_roll_scenes.size():
			selected_scene = forced_roll_scenes[i]
		else:
			selected_scene = available_dice_scenes[randi() % available_dice_scenes.size()]
		var dice = selected_scene.instantiate() as RigidBody3D
		if dice == null:
			continue
		add_child(dice)
		dice.global_position = _get_spawn_position(i)
		dice.global_rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		dice.apply_central_impulse(Vector3(
			randf_range(-1.2, 1.2),
			randf_range(2.88, 3.6),
			randf_range(-1.2, 1.2)
		))
		dice.apply_torque_impulse(Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		))
		active_dice.append(dice)

	await _wait_for_dice_to_settle()
	var results = _show_roll_result()
	if increment_counter:
		next_roll_count = min(next_roll_count + 1, max_dice_per_roll)
	roll_in_progress = false
	forced_roll_scenes.clear()
	roll_completed.emit(results)

func _wait_for_dice_to_settle() -> void:
	var elapsed := 0.0
	var stable_time := 0.0

	while elapsed < MAX_WAIT_SECONDS:
		var all_settled := true
		for dice in active_dice:
			if dice == null or not is_instance_valid(dice):
				continue
			if dice.sleeping:
				continue
			if dice.linear_velocity.length() > STABLE_LINEAR_THRESHOLD:
				all_settled = false
				break
			if dice.angular_velocity.length() > STABLE_ANGULAR_THRESHOLD:
				all_settled = false
				break

		if all_settled:
			stable_time += 0.1
			if stable_time >= REQUIRED_STABLE_TIME:
				return
		else:
			stable_time = 0.0

		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

func _show_roll_result() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for dice in active_dice:
		if dice == null or not is_instance_valid(dice):
			continue
		if dice.has_method("get_top_result_data"):
			var result := dice.call("get_top_result_data") as Dictionary
			if not result.is_empty():
				results.append(result)
				continue
		var fallback := {
			"value": int(dice.call("get_top_value")) if dice.has_method("get_top_value") else 1,
			"label": str(dice.call("get_top_name")) if dice.has_method("get_top_name") else "Risultato",
			"face_id": int(dice.call("get_top_face_id")) if dice.has_method("get_top_face_id") else 1,
			"symbol_texture": null,
			"dice_type": str(dice.call("get_dice_type")) if dice.has_method("get_dice_type") else "",
			"dice_name": ""
		}
		results.append(fallback)
	return results

func _get_available_dice_scenes() -> Array:
	var available: Array = []
	for scene in forced_roll_scenes:
		if scene != null:
			available.append(scene)
	for scene in dice_scenes:
		if scene != null:
			available.append(scene)
	if available.is_empty() and dice_scene != null:
		available.append(dice_scene)
	return available

func _get_spawn_position(index: int) -> Vector3:
	var angle := randf() * TAU
	var distance := sqrt(randf()) * SPAWN_RADIUS
	var offset := Vector3(cos(angle) * distance, float(index) * SPAWN_HEIGHT_STEP, sin(angle) * distance)
	return SPAWN_CENTER + offset

func _clear_dice() -> void:
	for dice in active_dice:
		if dice != null and is_instance_valid(dice):
			dice.queue_free()
	active_dice.clear()
