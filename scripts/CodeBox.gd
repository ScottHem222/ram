extends Control

@export var snap_slots := 7
@export var block_height := 162.0
@export var tile_size := 64.0

var slot_positions: Array[float] = []
var slot_occupants: Array[Node] = [] # can still contain null


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
	
func run_blocks(robot: Node) -> void:
	print("RUN pressed. Robot =", robot)
	apply_if_blocks(robot)

	for i in range(snap_slots):
		var block = slot_occupants[i]
		print("slot", i, "=", block)

		if block == null:
			continue

		# Best: put MoveBlock nodes in a group named "move_block"
		if block.is_in_group("move_block"):
			var units := _get_move_units(block)
			print("  MoveBlock units =", units)

			var distance := float(units) * tile_size
			if robot.has_method("move_step"):
				await robot.move_step(distance)
			else:
				push_error("Robot has no move_step(distance) method")


func _get_move_units(block: Node) -> int:
	var units_node := block.find_child("units", true, false) # recursive
	if units_node == null:
		push_warning("No node named 'units' found under %s" % block.name)
		return 0
		
	# LineEdit
	if units_node is LineEdit:
		print("units text =", units_node.text)
		return int(units_node.text)
		

	push_warning("Unsupported 'units' node type: %s" % [units_node.get_class()])
	return 0
	
func apply_if_blocks(robot: Node) -> void:
	robot.turn = false

	for i in range(snap_slots):
		var block := slot_occupants[i]
		if block == null:
			continue

		if block.is_in_group("if_block"):
			var cond := _get_text_field(block, "cond").to_lower()
			var then_txt := _get_text_field(block, "then").to_lower()
			print("Cond: ", cond)
			print("Then: ", then_txt)

			if cond == "obstacle" and then_txt == "turn":
				robot.turn = true
				return  # one match is enough


func _get_text_field(block: Node, field_name: String) -> String:
	var n := block.find_child(field_name, true, false)
	if n == null:
		return ""
	if n is LineEdit:
		return n.text.strip_edges()
	return ""
