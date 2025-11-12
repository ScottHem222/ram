extends Control

@export var snap_slots := 7
@export var block_height := 162.0

var slot_positions: Array = []
var slot_occupants: Array = []

func _ready():
	_initialize_slots()

func _initialize_slots():
	slot_positions.clear()
	slot_occupants.clear()

	var usable_space = size.y - block_height
	var step = usable_space / float(snap_slots - 1)
	for i in range(snap_slots):
		var y = global_position.y + i * step
		slot_positions.append(y)
		slot_occupants.append(null)

func find_nearest_slot(block_y: float) -> int:
	var nearest := 0
	var min_dist := INF
	for i in range(slot_positions.size()):
		var d = abs(block_y - slot_positions[i])
		if d < min_dist:
			min_dist = d
			nearest = i
	return nearest

func is_slot_free(idx: int) -> bool:
	return slot_occupants[idx] == null

func occupy_slot(idx: int, block: Node) -> void:
	slot_occupants[idx] = block

func clear_slot(block: Node) -> void:
	for i in range(slot_occupants.size()):
		if slot_occupants[i] == block:
			slot_occupants[i] = null
			break
