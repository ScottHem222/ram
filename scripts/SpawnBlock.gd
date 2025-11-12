extends Button

@export var block_scene: PackedScene
@export var block_bound_box: Node   # This is your BlockBoundBox ColorRect

func _pressed() -> void:
	if block_bound_box == null:
		push_error("BlockBoundBox not assigned!")
		return

	# Find next free slot
	var next_slot: int = -1
	for i: int in range(block_bound_box.snap_slots):
		if block_bound_box.is_slot_free(i):
			next_slot = i
			break

	# No free slots left
	if next_slot == -1:
		print("No free slots in BlockBoundBox.")
		return

	# Instance new DragBlock
	var new_block: Node = block_scene.instantiate()

	# Tell the block which boundary box it belongs to
	new_block.boundary_node = block_bound_box

	# Add it to the same parent as the button (usually the main scene)
	get_parent().add_child(new_block)

	# Determine snapped position
	var slot_y: float = block_bound_box.slot_positions[next_slot]
	var centered_x: float = block_bound_box.global_position.x + (block_bound_box.size.x - new_block.size.x) / 2.0

	# Position the block directly into the slot
	new_block.global_position = Vector2(centered_x, slot_y)

	# Mark slot as occupied
	block_bound_box.occupy_slot(next_slot, new_block)

	# Update the block's internal slot index
	new_block.current_slot = next_slot
