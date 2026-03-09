extends Node2D

@export var master_tilemap_path: NodePath = ^"TM_master"
@onready var tm_master: TileMapLayer = get_node(master_tilemap_path)

# cell -> [source_id:int, atlas:Vector2i, alt:int]
var _original_cells: Dictionary = {}
var _captured: bool = false


func _ready() -> void:
	# Capture immediately when level loads (original pristine state)
	add_to_group("level_4_root")
	capture_original_tilemap()


# Call this right before your code starts running (optional, but you asked for it)
func ensure_original_captured() -> void:
	if not _captured:
		capture_original_tilemap()


func capture_original_tilemap() -> void:
	_original_cells.clear()

	# Snapshot only the actually-painted cells
	for cell: Vector2i in tm_master.get_used_cells():
		var sid := tm_master.get_cell_source_id(cell)
		if sid == -1:
			continue
		var atlas := tm_master.get_cell_atlas_coords(cell)
		var alt := tm_master.get_cell_alternative_tile(cell)
		_original_cells[cell] = [sid, atlas, alt]

	_captured = true
	print("TM_master snapshot saved. Cells:", _original_cells.size())


func restore_tilemap_to_original() -> void:
	if not _captured:
		capture_original_tilemap()

	# Clear current painted cells (including mined tunnels etc.)
	for cell: Vector2i in tm_master.get_used_cells():
		tm_master.erase_cell(cell)

	# Rebuild original
	for cell in _original_cells.keys():
		var data = _original_cells[cell]
		tm_master.set_cell(cell, data[0], data[1], data[2])

	print("TM_master restored to original.")
