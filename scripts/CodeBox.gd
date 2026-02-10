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
	

func _get_slot_size(block: Node) -> int:
	if block != null:
		return maxi(1, int(block.slot_size))
	return 1


# ---------------------------------------------------------
# Called both when dragging begins AND when deleting:
# Removes block from array and auto-shuffles other blocks up
# ---------------------------------------------------------
func clear_slot(block: Node) -> void:
	var first := -1

	# Clear every slot that points to this block
	for i in range(slot_occupants.size()):
		if slot_occupants[i] == block:
			if first == -1:
				first = i
			slot_occupants[i] = null

	# If we cleared something, compact everything down
	if first != -1:
		_compact_slots()


# ---------------------------------------------------------
# Shuffle every block below upwards by 1 slot
# Used when a block gets deleted above
# ---------------------------------------------------------
func _has_prop(obj: Object, prop_name: StringName) -> bool:
	for p in obj.get_property_list():
		if StringName(p.name) == prop_name:
			return true
	return false

func _get_int_prop(obj: Object, prop_name: StringName, default_val: int) -> int:
	if _has_prop(obj, prop_name):
		return int(obj.get(prop_name))
	return default_val

func _compact_slots() -> void:
	var seen := {}
	var blocks_in_order: Array[Node] = []

	for i in range(snap_slots):
		var b := slot_occupants[i]
		if b == null:
			continue
		if not seen.has(b):
			seen[b] = true
			blocks_in_order.append(b)

	for i in range(snap_slots):
		slot_occupants[i] = null

	var write_idx := 0
	for b in blocks_in_order:
		var sz := _get_int_prop(b, &"slot_size", 1)
		sz = maxi(sz, 1)

		if write_idx + sz > snap_slots:
			break

		for j in range(sz):
			slot_occupants[write_idx + j] = b

		if b.has_method("snap_to_slot"):
			b.snap_to_slot(write_idx)

		if _has_prop(b, &"current_slot"):
			b.set(&"current_slot", write_idx)

		write_idx += sz
	
func run_blocks(robot: Node) -> void:
	print("RUN pressed. Robot =", robot)
	
	apply_if_blocks(robot)
	
	if LevelState.curr_lvl == 4:
		apply_for_loop(robot)

	var seen := {}
	var in_while = apply_while_loop(robot)

	for i in range(snap_slots):
		var block: Node = slot_occupants[i]
		if block == null:
			continue
		if seen.has(block):
			continue
		seen[block] = true

		print("slot", i, "=", block)
		
		if block.is_in_group("a_move_block"):
			robot.turn = true
			await  robot.move_step(100000)
			

		elif block.is_in_group("move_block"):
			var units := _get_move_units(block)
			var distance := float(units) * tile_size
			await robot.move_step(distance)

		elif block.is_in_group("turn_block"):
			var dir := _get_turn_dir(block)
			if dir == 0:
				robot.turn_left()
			elif dir == 1:
				robot.turn_right()

	robot.check_done_cond(in_while)
			


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
	
# 0 Left , 1 Right, 2 invalid
func _get_turn_dir(block: Node) -> int:
	
	var units_node := block.find_child("dir", true, false) # recursive
	if units_node == null:
		push_warning("No node named 'units' found under %s" % block.name)
		return 0
		
	# LineEdit
	if units_node is LineEdit:
		var ut = units_node.text.to_lower()
		print("units text =", ut)
		if ut == "left":
			return 0
		elif ut == "right":
			return 1
	
	return 2
	
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

			if cond == "obstacle":
				if then_txt == "turn()":
					robot.turn = true
				elif then_txt == "stop()":
					robot.auto_stop = true
			
			elif cond == "gold" and then_txt == "stop()":
				robot.auto_stop = true
				
				
func apply_while_loop(robot: Node) -> bool:
	
	
	for i in range(snap_slots):
		var block := slot_occupants[i]
		if block == null:
			continue
			
		if block.is_in_group("while_block"):
			var cond := _get_text_field(block, "cond").to_lower()
			var do := _get_text_field(block, "do").to_lower()
			
			if (cond == "notatgoal" or cond == "true") and do == "move()":
				robot.move_step(1000000)
				return true
	
	return false
	
	
func apply_for_loop(robot: Node) -> void:
	
	for i in range(snap_slots):
		var block := slot_occupants[i]
		if block == null:
			continue
			
		if block.is_in_group("for_block"):
			var fld_for := _get_text_field(block, "for").to_lower()
			var fld_in := _get_text_field(block, "in").to_lower()
			var fld_do := _get_text_field(block, "do").to_lower()
			
			if fld_for == "gold" and fld_in == "mine":
				
				if fld_do == "mine()":
					robot.mine_gold = true
			
	
	


func _get_text_field(block: Node, field_name: String) -> String:
	var n := block.find_child(field_name, true, false)
	if n == null:
		return ""
	if n is LineEdit:
		return n.text.strip_edges()
	return ""
