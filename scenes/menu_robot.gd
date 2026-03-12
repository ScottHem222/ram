extends CharacterBody2D

@export var speed: float = 150.0
@export var turn_degrees: float = 90.0
@export var tilemap_path: NodePath

@export var random_turn_chance: float = 0.01   

@onready var tilemap: TileMapLayer = get_node(tilemap_path)

var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	randomize()


func _physics_process(_delta: float) -> void:
	if tilemap == null:
		return

	# Turn if wall ahead
	if _is_wall_ahead():
		_turn_random()

	# Random wandering turn
	elif randf() < random_turn_chance:
		_turn_random()

	# Move forward
	rotation = direction.angle()
	velocity = direction.normalized() * speed
	move_and_slide()


# -------------------------
# TILE CHECKING (grid-based)
# -------------------------
func _cell_under_robot() -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(global_position))


func _step_vec() -> Vector2i:
	# Snap to cardinal directions only
	if absf(direction.x) >= absf(direction.y):
		return Vector2i(int(sign(direction.x)), 0)
	else:
		return Vector2i(0, int(sign(direction.y)))


func _cell_ahead() -> Vector2i:
	return _cell_under_robot() + _step_vec()


func _is_wall_ahead() -> bool:
	var td: TileData = tilemap.get_cell_tile_data(_cell_ahead())
	if td == null:
		return false

	if td.has_custom_data("type"):
		var t := String(td.get_custom_data("type"))
		return t.begins_with("wall")

	return false


# -------------------------
# TURNING
# -------------------------
func _turn_random() -> void:
	var tsign := 1 if randi() % 2 == 0 else -1
	direction = direction.rotated(tsign * deg_to_rad(turn_degrees))
