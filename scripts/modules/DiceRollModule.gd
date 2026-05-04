extends Node3D

@export var dice_scene: PackedScene
@export var max_dice_per_roll: int = 12

@onready var info_label: Label = $CanvasLayer/DiceWindow/MarginContainer/VBoxContainer/InfoLabel
@onready var result_label: Label = $CanvasLayer/DiceWindow/MarginContainer/VBoxContainer/ResultLabel

var active_dice: Array[RigidBody3D] = []
var next_roll_count: int = 1
var roll_in_progress: bool = false

const SPAWN_CENTER := Vector3(0.0, 2.2, 0.0)
const STABLE_LINEAR_THRESHOLD := 0.05
const STABLE_ANGULAR_THRESHOLD := 0.05
const REQUIRED_STABLE_TIME := 0.35
const MAX_WAIT_SECONDS := 6.0

func _ready() -> void:
	randomize()
	_update_labels_idle()
	if dice_scene == null:
		result_label.text = "Errore: scena del dado non assegnata."

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_start_roll()

func _start_roll() -> void:
	if roll_in_progress or dice_scene == null:
		return
	_clear_dice()
	roll_in_progress = true
	info_label.text = "Lancio in corso: %d dado/i" % next_roll_count
	result_label.text = "I dadi stanno rotolando..."

	for i in next_roll_count:
		var dice := dice_scene.instantiate() as RigidBody3D
		if dice == null:
			continue
		add_child(dice)
		dice.global_position = SPAWN_CENTER + Vector3((i - (next_roll_count - 1) * 0.5) * 0.7, 0.0, 0.0)
		dice.global_rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		dice.apply_central_impulse(Vector3(
			randf_range(-1.2, 1.2),
			randf_range(4.8, 6.0),
			randf_range(-1.2, 1.2)
		))
		dice.apply_torque_impulse(Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		))
		active_dice.append(dice)

	await _wait_for_dice_to_settle()
	_show_roll_result()
	next_roll_count = min(next_roll_count + 1, max_dice_per_roll)
	roll_in_progress = false
	_update_labels_idle()

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

func _show_roll_result() -> void:
	var values: Array[int] = []
	var labels: Array[String] = []
	var total := 0

	for dice in active_dice:
		if dice == null or not is_instance_valid(dice):
			continue
		var value := 1
		if dice.has_method("get_top_value"):
			value = int(dice.call("get_top_value"))
		values.append(value)
		total += value
		if dice.has_method("get_top_name"):
			labels.append(str(dice.call("get_top_name")))
		else:
			labels.append(str(value))

	if values.is_empty():
		result_label.text = "Nessun risultato disponibile."
		return

	result_label.text = "Risultati: %s | Totale spade: %d" % [", ".join(labels), total]

func _to_string_array(values: Array[int]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(str(value))
	return out

func _update_labels_idle() -> void:
	if roll_in_progress:
		return
	info_label.text = "Premi SPAZIO per lanciare %d dado/i" % next_roll_count

func _clear_dice() -> void:
	for dice in active_dice:
		if dice != null and is_instance_valid(dice):
			dice.queue_free()
	active_dice.clear()
