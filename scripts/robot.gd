extends CharacterBody2D

@export var speed: float = 200.0
@export var turn_degrees: float = 90.0
@onready var ray: RayCast2D = $ray_fw

@export var tilemap_path: NodePath
@onready var tilemap: TileMapLayer = get_node(tilemap_path)

signal onr()
signal blocked()
signal gold_reached()

var auto_move: bool = false
var turn: bool = false
var direction: Vector2 = Vector2.RIGHT

# --- step-move state ---
signal step_finished
var _step_active: bool = false
var _step_remaining: float = 0.0
var _step_dir: Vector2 = Vector2.RIGHT
var _just_turned: bool = false


func _physics_process(delta: float) -> void:
	if auto_move:
		if turn and ray.is_colliding():
			if randi() % 2 == 0:
				direction = direction.rotated(deg_to_rad(turn_degrees))
			else:
				direction = direction.rotated(-deg_to_rad(turn_degrees))

		velocity = direction.normalized() * speed
		move_and_slide()
		rotation = direction.angle()
		return

	# --- step movement uses the SAME look/feel as auto_move ---
	if _step_active:
		rotation = _step_dir.angle()

		var step_dist: float = minf(speed * delta, _step_remaining)

		# Move exactly step_dist this frame via move_and_slide()
		var safe_delta: float = maxf(delta, 0.000001)
		velocity = _step_dir * (step_dist / safe_delta)
		move_and_slide()

		var moved: float = get_last_motion().length()
		_step_remaining -= moved

		# ✅ NEW: check for GOLD during movement (not just at the end)
		if check_tile_ahead() == "gold":
			_step_remaining = 0.0
			_step_active = false
			velocity = Vector2.ZERO
			gold_reached.emit()
			step_finished.emit()
			return

		# Detect obstacle in front via collisions (border walls + tiles)
		var hit_ahead := false
		for j in range(get_slide_collision_count()):
			var c := get_slide_collision(j)
			if c.get_normal().dot(_step_dir) < -0.7:
				hit_ahead = true
				break

		if hit_ahead:
			if turn:
				if not _just_turned:
					_just_turned = true
					if randi() % 2 == 0:
						direction = direction.rotated(deg_to_rad(turn_degrees))
					else:
						direction = direction.rotated(-deg_to_rad(turn_degrees))
					_step_dir = direction.normalized()
					rotation = direction.angle()
				else:
					_step_remaining = 0.0
			else:
				_step_remaining = 0.0
		else:
			_just_turned = false

		if _step_remaining <= 0.0:
			_step_active = false
			velocity = Vector2.ZERO

			# keep your original end-of-step behavior
			var t := check_tile_ahead()
			if t == "gold":
				gold_reached.emit()
			elif t == "stone":
				blocked.emit()
			else:
				onr.emit()

			step_finished.emit()
			return

	velocity = Vector2.ZERO


func move_step(distance: float) -> void:
	if auto_move or _step_active:
		return

	_step_dir = direction.normalized()
	_step_remaining = absf(distance)
	_step_active = true
	_just_turned = false

	await step_finished


func reset_pos() -> void:
	position = Vector2.ZERO


func check_tile_ahead() -> String:
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step

	var td: TileData = tilemap.get_cell_tile_data(ahead_cell)
	if td == null:
		return ""

	if td.has_custom_data("type"):
		return String(td.get_custom_data("type"))

	return ""
