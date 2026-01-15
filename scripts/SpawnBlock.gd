extends Button

@export var block_scene: PackedScene
@export var block_bound_box: Node
@export var count_var_name: String = "move_blocks" # or "if_blocks" in inspector

@onready var main = get_tree().current_scene

func _ready():
	# Wait for main to finish its _ready() where it sets counts
	if not main.is_node_ready():
		await main.ready

	# Connect to main's signal (make sure main.gd has: signal block_count_changed)
	if main.has_signal("block_count_changed"):
		# Avoid double-connecting if this node gets re-added for any reason
		if not main.is_connected("block_count_changed", Callable(self, "_on_block_count_changed")):
			main.connect("block_count_changed", Callable(self, "_on_block_count_changed"))

	# Initial paint
	_on_block_count_changed()


func _on_block_count_changed():
	$CountBox/Count.text = str(main.get(count_var_name))


func _pressed() -> void:
	if main.get(count_var_name) > 0:

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

		# Decrement correct counter
		main.set(count_var_name, main.get(count_var_name) - 1)

		# NEW: tell all UI to refresh
		if main.has_signal("block_count_changed"):
			main.emit_signal("block_count_changed")
