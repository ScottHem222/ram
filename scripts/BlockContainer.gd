extends VBoxContainer

func _can_drop_data(position: Vector2, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("block")

func _drop_data(position: Vector2, data):
	var block = data["block"]
	if not is_instance_valid(block): return
	var insert_index = get_index_at_position(position)
	block.get_parent().remove_child(block)
	add_child(block)
	move_child(block, insert_index)

func get_index_at_position(pos: Vector2) -> int:
	for i in range(get_child_count()):
		var c = get_child(i)
		if pos.y < c.position.y + c.size.y / 2.0:
			return i
	return get_child_count()
