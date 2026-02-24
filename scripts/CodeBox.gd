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
	if robot == null:
		push_error("run_blocks: robot is null")
		return

	print("RUN pressed. Robot =", robot)

	# Reset per-run robot flags so old runs don't leak
	_reset_robot_run_flags(robot)

	# Apply rule blocks that change robot behavior
	_apply_if_blocks(robot)
	if LevelState.curr_lvl == 4:
		_apply_for_blocks(robot)

	# Execute in order
	var blocks := _get_unique_blocks_in_order()

	# If a WHILE block exists and is valid, run it and stop (it "owns" execution)
	var in_while := await _try_run_while(robot, blocks)
	if in_while:
		if robot.has_method("check_done_cond"):
			robot.check_done_cond(true)
		return

	# Otherwise run sequentially
	for block in blocks:
		if block.is_in_group("a_move_block"):
			# "auto move until something stops it"
			if _has_prop(robot, &"turn"):
				robot.turn = true
			if robot.has_method("move_step_infinite"):
				await robot.move_step_infinite()
			else:
				await robot.move_step(1000000.0)

		elif block.is_in_group("move_block"):
			var units := _get_move_units(block)
			var distance := float(units) * float(robot.tile_size)
			await robot.move_step(distance)

		elif block.is_in_group("turn_block"):
			var dir := _get_turn_dir(block)
			if dir == 0 and robot.has_method("turn_left"):
				robot.turn_left()
			elif dir == 1 and robot.has_method("turn_right"):
				robot.turn_right()

	# End condition after all blocks
	if robot.has_method("check_done_cond"):
		robot.check_done_cond(false)


# -----------------------------
# Build a unique ordered list of blocks (top->bottom)
# -----------------------------
func _get_unique_blocks_in_order() -> Array[Node]:
	var seen := {}
	var out: Array[Node] = []

	for i in range(snap_slots):
		var b: Node = slot_occupants[i]
		if b == null:
			continue
		if seen.has(b):
			continue
		seen[b] = true
		out.append(b)

	return out


# -----------------------------
# Reset robot flags each RUN
# -----------------------------
func _reset_robot_run_flags(robot: Node) -> void:
	if _has_prop(robot, &"turn"):
		robot.turn = false
	if _has_prop(robot, &"auto_stop"):
		robot.auto_stop = false
	if _has_prop(robot, &"mine_gold"):
		robot.mine_gold = false


# -----------------------------
# IF blocks (rules)
# -----------------------------
func _apply_if_blocks(robot: Node) -> void:
	for b in _get_unique_blocks_in_order():
		if not b.is_in_group("if_block"):
			continue

		var cond := _get_text_field(b, "cond").to_lower()
		var then_txt := _get_text_field(b, "then").to_lower()

		# obstacle -> turn/stop
		if cond == "obstacle":
			if then_txt == "turn()":
				if _has_prop(robot, &"turn"):
					robot.turn = true
			elif then_txt == "stop()":
				if _has_prop(robot, &"auto_stop"):
					robot.auto_stop = true

		# gold -> mine for lvl 4
		if cond == "gold" and then_txt == "mine()":
			robot.mine_gold = true


# -----------------------------
# FOR blocks (level 4 mining)
# -----------------------------
func _apply_for_blocks(robot: Node) -> void:
	for b in _get_unique_blocks_in_order():
		if not b.is_in_group("for_block"):
			continue

		var fld_for := _get_text_field(b, "for").to_lower()
		var fld_in := _get_text_field(b, "in").to_lower()
		var fld_do := _get_text_field(b, "do").to_lower()

		if fld_for == "gold" and fld_in == "mine" and fld_do == "mine()":
			if _has_prop(robot, &"mine_gold"):
				robot.mine_gold = true
				print("FOR BLOCK: mining enabled")


# -----------------------------
# WHILE blocks
# Returns true if a while loop was executed
# -----------------------------
func _is_at_goal(robot: Node) -> bool:
	# Goal is true if gold is under robot OR ahead
	if robot.has_method("check_tile_here") and robot.check_tile_here() == "gold":
		return true
	if robot.has_method("check_tile_ahead") and robot.check_tile_ahead() == "gold":
		return true
	return false


func _while_condition_true(robot: Node, cond: String) -> bool:
	if cond == "true":
		return true
	if cond == "notatgoal":
		return not _is_at_goal(robot)
	return false


func _while_do(robot: Node, do_txt: String) -> bool:
	if do_txt != "move()":
		return false

	var before = robot.global_position

	if robot.has_method("move_step_infinite"):
		await robot.move_step_infinite()
	elif robot.has_method("move_step"):
		await robot.move_step(1000000.0)
	else:
		return false

	var after = robot.global_position
	return before.distance_to(after) > 1.0


func _try_run_while(robot: Node, blocks: Array[Node]) -> bool:
	for b in blocks:
		if not b.is_in_group("while_block"):
			continue

		var cond := _get_text_field(b, "cond").to_lower()
		var do_txt := _get_text_field(b, "do").to_lower()

		if not _while_condition_true(robot, cond):
			return false

		# Run WHILE until condition false (with a safety cap)
		var safety := 200
		while _while_condition_true(robot, cond) and safety > 0:
			safety -= 1

			var did := await _while_do(robot, do_txt)

			# IMPORTANT: after each move, re-check goal immediately
			# (covers the case where IF turns and "ahead" changes, or gold is under robot)
			if _is_at_goal(robot):
				break

			if not did:
				break

		return true

	return false


# -----------------------------
# Existing helpers 
# -----------------------------
func _get_move_units(block: Node) -> int:
	var units_node := block.find_child("units", true, false)
	if units_node is LineEdit:
		return int(units_node.text)
	return 0

# 0 left, 1 right, 2 invalid
func _get_turn_dir(block: Node) -> int:
	var dir_node := block.find_child("dir", true, false)
	if dir_node is LineEdit:
		var t: String = dir_node.text.strip_edges().to_lower()
		if t == "left":
			return 0
		if t == "right":
			return 1
	return 2

func _get_text_field(block: Node, field_name: String) -> String:
	var n := block.find_child(field_name, true, false)
	return n.text.strip_edges() if n is LineEdit else ""

	
