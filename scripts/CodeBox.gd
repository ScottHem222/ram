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


# ---------------------------------------------------------
# Get the highest free slot (slot 0 first, then 1,2,...)
# ---------------------------------------------------------
func get_highest_free_slot() -> int:
	for i in range(snap_slots):
		if slot_occupants[i] == null:
			return i
	return -1   # No free slots


func is_slot_free(idx: int) -> bool:
	return slot_occupants[idx] == null


func occupy_slot(idx: int, block: Node) -> void:
	slot_occupants[idx] = block


# ---------------------------------------------------------
# Called both when dragging begins AND when deleting:
# Removes block from array and auto-shuffles other blocks up
# ---------------------------------------------------------
func clear_slot(block: Node) -> void:
	for i in range(slot_occupants.size()):
		if slot_occupants[i] == block:
			slot_occupants[i] = null
			_shuffle_up_from(i)
			return


# ---------------------------------------------------------
# Shuffle every block below upwards by 1 slot
# Used when a block gets deleted above
# ---------------------------------------------------------
func _shuffle_up_from(start_slot: int) -> void:
	for i in range(start_slot, snap_slots - 1):
		slot_occupants[i] = slot_occupants[i + 1]

		# If a block occupies new index, tell it to snap to this slot
		if slot_occupants[i] != null:
			slot_occupants[i].snap_to_slot(i)

	# Last slot becomes empty
	slot_occupants[snap_slots - 1] = null
