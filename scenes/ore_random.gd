extends Node2D

@export var tilemap_path: NodePath
var tilemap: TileMapLayer

@export var ore_source_id: int = 1

# atlas coordinates of ores in the tileset
@export var ore_gold_atlas: Vector2i = Vector2i(4,1)
@export var ore_blue_atlas: Vector2i = Vector2i(3,1)
@export var ore_pink_atlas: Vector2i = Vector2i(1,1)
@export var ore_green_atlas: Vector2i = Vector2i(2,1)

@export var ore_alt: int = 0


func _ready():
	tilemap = get_node(tilemap_path)


func randomise_ores():

	var ore_choices = [
		ore_gold_atlas,
		ore_blue_atlas,
		ore_pink_atlas,
		ore_green_atlas
	]

	var cells = tilemap.get_used_cells()

	for cell in cells:

		var td = tilemap.get_cell_tile_data(cell)
		if td == null:
			continue

		if not td.has_custom_data("type"):
			continue

		if td.get_custom_data("type") != "gold":
			continue

		var atlas = ore_choices.pick_random()
		tilemap.set_cell(cell, ore_source_id, atlas, ore_alt)
