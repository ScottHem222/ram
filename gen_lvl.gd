extends Node

@export var tilemap_path: NodePath
@onready var tilemap: TileMapLayer = get_node(tilemap_path)

@export var wall_type_prefix: String = "wall"
@export var fill_tiles: Array = [
	[1, Vector2i(4,0), 0, 50],
	[1, Vector2i(0,1), 0, 3],
	[1, Vector2i(4,1), 0, 2],
	[1, Vector2i(3,1), 0, 1],
	[1, Vector2i(2,1), 0, 1],
	[1, Vector2i(1,1), 0, 1],
]

@export var only_fill_empty_cells: bool = true
@export var extra_margin: int = 2

func generate_inside_from_boundary() -> void:

	# compute bounds of used cells
	var used := tilemap.get_used_cells()
	if used.is_empty():
		push_error("Tilemap has no used cells.")
		return

	var minx := used[0].x
	var maxx := used[0].x
	var miny := used[0].y
	var maxy := used[0].y
	for c in used:
		minx = mini(minx, c.x)
		maxx = maxi(maxx, c.x)
		miny = mini(miny, c.y)
		maxy = maxi(maxy, c.y)

	minx -= extra_margin
	miny -= extra_margin
	maxx += extra_margin
	maxy += extra_margin

	# mark wall cells in bounds
	var walls := {}
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var cell := Vector2i(x, y)
			if _is_wall_cell(cell):
				walls[cell] = true

	# fill walls
	var outside := {}
	var q: Array[Vector2i] = []

	# enqueue border cells
	for x in range(minx, maxx + 1):
		q.append(Vector2i(x, miny))
		q.append(Vector2i(x, maxy))
	for y in range(miny, maxy + 1):
		q.append(Vector2i(minx, y))
		q.append(Vector2i(maxx, y))

	for start in q:
		if walls.has(start):
			continue
		if outside.has(start):
			continue
		_flood_outside(start, minx, miny, maxx, maxy, walls, outside)

	# get inside wall tiles
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var cell := Vector2i(x, y)
			if walls.has(cell):
				continue
			if outside.has(cell):
				continue

			# inside
			if only_fill_empty_cells and tilemap.get_cell_source_id(cell) != -1:
				continue

			var choice := _weighted_pick(rng)
			tilemap.set_cell(cell, choice.source_id, choice.atlas, choice.alt)

	print("Generated interior tiles.")

# -------------------------
# Helpers
# -------------------------
func _is_wall_cell(cell: Vector2i) -> bool:
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return false
	if td.has_custom_data("type"):
		var t := String(td.get_custom_data("type"))
		return t.begins_with(wall_type_prefix)
	return false

func _flood_outside(start: Vector2i, minx: int, miny: int, maxx: int, maxy: int, walls: Dictionary, outside: Dictionary) -> void:
	var stack: Array[Vector2i] = [start]
	outside[start] = true

	while not stack.is_empty():
		var c = stack.pop_back()
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n = c + d
			if n.x < minx or n.x > maxx or n.y < miny or n.y > maxy:
				continue
			if walls.has(n):
				continue
			if outside.has(n):
				continue
			outside[n] = true
			stack.append(n)

class TileChoice:
	var source_id: int
	var atlas: Vector2i
	var alt: int
	func _init(sid: int, a: Vector2i, al: int) -> void:
		source_id = sid
		atlas = a
		alt = al

func _weighted_pick(rng: RandomNumberGenerator) -> TileChoice:
	var total := 0.0
	for opt in fill_tiles:
		total += float(opt[3])

	var r := rng.randf() * total
	var acc := 0.0
	for opt in fill_tiles:
		acc += float(opt[3])
		if r <= acc:
			return TileChoice.new(int(opt[0]), Vector2i(opt[1]), int(opt[2]))

	# fallback
	var o = fill_tiles[0]
	return TileChoice.new(int(o[0]), Vector2i(o[1]), int(o[2]))
	
	
