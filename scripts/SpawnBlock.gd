extends Button

@export var block_scene: PackedScene
@export var block_bound_box: Node
@export var count_var_name: String = "move_blocks"

@onready var main = get_tree().current_scene

func _ready():
	if not main.is_node_ready():
		await main.ready

	if main.has_signal("block_count_changed"):
		if not main.is_connected("block_count_changed", Callable(self, "_on_block_count_changed")):
			main.connect("block_count_changed", Callable(self, "_on_block_count_changed"))

	_on_block_count_changed()


func _on_block_count_changed():
	$CountBox/Count.text = str(main.get(count_var_name))


func _pressed() -> void:
	if main.get(count_var_name) <= 0:
		return

	if block_bound_box == null:
		push_error("BlockBoundBox not assigned!")
		return

	# Instance block first so we can read its slot_size
	var new_block: Node = block_scene.instantiate()
	var slot_size := 1
	slot_size = int(new_block.slot_size)

	# Find first stretch of free slots big enough
	var start_slot := -1
	for i in range(block_bound_box.snap_slots - slot_size + 1):
		var fits := true
		for j in range(slot_size):
			if not block_bound_box.is_slot_free(i + j):
				fits = false
				break
		if fits:
			start_slot = i
			break

	if start_slot == -1:
		print("Not enough space for block of size", slot_size)
		return

	# Add block to scene
	new_block.boundary_node = block_bound_box
	get_parent().add_child(new_block)

	# Position block
	var slot_y: float = block_bound_box.slot_positions[start_slot]
	var centered_x: float = block_bound_box.global_position.x + (block_bound_box.size.x - new_block.size.x) / 2.0
	new_block.global_position = Vector2(centered_x, slot_y)

	# Occupy all slots the block needs
	for k in range(slot_size):
		block_bound_box.occupy_slot(start_slot + k, new_block)

	new_block.current_slot = start_slot

	# Decrement counter
	main.set(count_var_name, main.get(count_var_name) - 1)
	main.emit_signal("block_count_changed")
