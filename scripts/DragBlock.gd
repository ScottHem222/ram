extends Control

@export var boundary_node: Node    
@export var snap_slots := 7
@export var slot_size := 1
@export var count_var_name: StringName = &"move_blocks"

var dragging := false
var drag_offset := Vector2.ZERO
var current_slot := -1

@onready var delete_button = $DeleteButton
@onready var main := get_tree().current_scene


func _ready():
	delete_button.pressed.connect(_on_delete_pressed)


func _on_delete_pressed():
	# free slot and auto-shuffle others upward
	if boundary_node and current_slot != -1:
		boundary_node.clear_slot(self)

	# refund count
	if main != null:
		main.set(count_var_name, int(main.get(count_var_name)) + 1)
		# UI refresh
		main.emit_signal("block_count_changed")

	queue_free()


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = event.position

			# free old slot
			if boundary_node and current_slot != -1:
				boundary_node.clear_slot(self)
			current_slot = -1

		else:
			dragging = false
			_snap_to_highest_slot()

	elif event is InputEventMouseMotion and dragging and boundary_node:
		var new_pos = global_position + (event.position - drag_offset)
		var bbox = Rect2(boundary_node.global_position, boundary_node.size)

		# vertical clamp
		new_pos.y = clamp(new_pos.y, bbox.position.y, bbox.position.y + bbox.size.y - size.y)
		# keep horizontal position
		new_pos.x = bbox.position.x + (bbox.size.x - size.x) / 2.0

		global_position = new_pos


func _snap_to_highest_slot():
	if not boundary_node:
		return

	var slot = boundary_node.get_highest_free_slot()
	if slot == -1:
		return  # no free spaces

	snap_to_slot(slot)
	boundary_node.occupy_slot(slot, self)
	current_slot = slot


func snap_to_slot(idx):
	var snapped_y = boundary_node.slot_positions[idx]
	var bbox = boundary_node
	var centered_x = bbox.global_position.x + (bbox.size.x - size.x) / 2.0

	var tween = get_tree().create_tween()
	tween.tween_property(
		self,
		"global_position",
		Vector2(centered_x, snapped_y),
		0.15
	).set_ease(Tween.EASE_OUT)

	current_slot = idx
