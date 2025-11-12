extends Control

@export var boundary_node: Node
@export var snap_slots: int = 7

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var current_slot: int = -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = event.position
			if boundary_node:
				boundary_node.clear_slot(self)
			current_slot = -1
		else:
			dragging = false
			_snap_to_nearest_slot()
	elif event is InputEventMouseMotion and dragging and boundary_node:
		var new_pos: Vector2 = global_position + (event.position - drag_offset)
		var boundary_rect: Rect2 = Rect2(boundary_node.global_position, boundary_node.size)
		new_pos.y = clamp(new_pos.y, boundary_rect.position.y, boundary_rect.position.y + boundary_rect.size.y - size.y)
		new_pos.x = boundary_rect.position.x + (boundary_rect.size.x - size.x) / 2.0
		global_position = new_pos


func _snap_to_nearest_slot() -> void:
	if not boundary_node:
		return

	var nearest: int = boundary_node.find_nearest_slot(global_position.y)
	var target_slot: int = nearest

	# find first available slot if nearest is occupied
	if not boundary_node.is_slot_free(nearest):
		var found: bool = false
		for offset: int in range(1, snap_slots):
			var up: int = nearest - offset
			var down: int = nearest + offset
			if up >= 0 and boundary_node.is_slot_free(up):
				target_slot = up
				found = true
				break
			elif down < snap_slots and boundary_node.is_slot_free(down):
				target_slot = down
				found = true
				break

		if not found and current_slot != -1:
			target_slot = current_slot

	# always snap somewhere
	_occupy_slot(target_slot)


func _occupy_slot(idx: int) -> void:
	var snapped_y: float = boundary_node.slot_positions[idx]
	var centered_x: float = boundary_node.global_position.x + (boundary_node.size.x - size.x) / 2.0

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", Vector2(centered_x, snapped_y), 0.15).set_ease(Tween.EASE_OUT)

	boundary_node.occupy_slot(idx, self)
	current_slot = idx
