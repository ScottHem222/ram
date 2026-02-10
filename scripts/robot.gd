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
var auto_stop: bool = false
var mine_gold: bool = false

@export var gold_cell: Vector2i = Vector2i.ZERO
@export var gold_turn_bias: float = 0.75

# --- step-move state ---
signal step_finished
var _step_active: bool = false
var _step_remaining: float = 0.0
var _step_dir: Vector2 = Vector2.RIGHT
var _just_turned: bool = false

# Corner-escape state
var _turned_dir_sign: int = 0   # -1 = left, +1 = right, 0 = none
var _turn_attempts: int = 0     # how many turns we've tried while blocked this step

# hover panel
@export var tooltip_panel_path: NodePath
@export var tooltip_label_path: NodePath
var tooltip_panel
var tooltip_label

@onready var hover_area: Area2D = $HoverArea

var tt_methods_1: Array[String] = [
	"Move()",
	"Turn()",
	"Stop()",
	"Mine()"
]

# Scanning
@export var scanner_cell: Vector2i = Vector2i(22, 0)
@onready var scanner_tilemap: TileMapLayer = get_node("/root/Node2D/GameUILayer/level_UI/ScannerTile")
@onready var scanner_label: Label = get_node("/root/Node2D/GameUILayer/level_UI/scanner")


func _ready() -> void:
	tooltip_panel = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip")
	tooltip_label = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip/Text")
	hover_area.mouse_entered.connect(_on_robot_mouse_entered)
	hover_area.mouse_exited.connect(_on_robot_mouse_exited)
	tooltip_panel.visible = false
	add_to_group("robot")

	if LevelState.curr_lvl == 3:
		gold_cell = Vector2i(21, -6)


func _process(_delta: float) -> void:
	if tooltip_panel and tooltip_panel.visible:
		var screen_pos := get_viewport().get_canvas_transform() * global_position
		tooltip_panel.position = screen_pos + Vector2(40, -20)


func _on_robot_mouse_entered() -> void:
	var methods
	if LevelState.curr_lvl < 5:
		methods = tt_methods_1

	tooltip_label.text = "Robot Functions:\n- " + "\n- ".join(methods)
	tooltip_panel.visible = true


func _on_robot_mouse_exited() -> void:
	tooltip_panel.visible = false


func update_scanner_tile() -> void:
	if scanner_tilemap == null or tilemap == null:
		return

	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step

	var source_id: int = tilemap.get_cell_source_id(ahead_cell)
	if source_id == -1:
		scanner_tilemap.erase_cell(scanner_cell)
		return

	var atlas: Vector2i = tilemap.get_cell_atlas_coords(ahead_cell)
	var alt: int = tilemap.get_cell_alternative_tile(ahead_cell)
	scanner_tilemap.set_cell(scanner_cell, source_id, atlas, alt)

	var tile_name := check_tile_ahead()
	if tile_name == "tunnel":
		scanner_label.text = "SCANNER\nType: Tunnel\nValue: 0"
	elif tile_name.begins_with("wall") or tile_name == "stone":
		scanner_label.text = "SCANNER\nType: Obstacle\nValue: -1"
	elif tile_name.begins_with("gem"):
		scanner_label.text = "SCANNER\nType: Gem\nValue: 20"
	elif tile_name == "gold":
		scanner_label.text = "SCANNER\nType: Gold\nValue: 25"


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

	if _step_active:
		rotation = _step_dir.angle()

		var step_dist: float = minf(speed * delta, _step_remaining)
		var safe_delta: float = maxf(delta, 0.000001)
		velocity = _step_dir * (step_dist / safe_delta)
		move_and_slide()

		update_scanner_tile()

		var moved: float = get_last_motion().length()
		_step_remaining -= moved

		# If we actually moved, we are no longer "stuck turning"
		if moved > 0.001:
			_just_turned = false
			_turn_attempts = 0
			_turned_dir_sign = 0

		# Early gold detect (tile in front)
		if check_tile_ahead() == "gold":
			_step_remaining = 0.0
			_step_active = false
			velocity = Vector2.ZERO
			gold_reached.emit()
			step_finished.emit()
			return

		# Detect obstacle in front via collisions
		var hit_ahead := false
		for j in range(get_slide_collision_count()):
			var c := get_slide_collision(j)
			if c.get_normal().dot(_step_dir) < -0.7:
				hit_ahead = true
				break

		if hit_ahead:
			if turn:
				# If we already turned once and are still blocked, try the opposite turn once.
				if _just_turned:
					if _turn_attempts < 2:
						_turn_attempts += 1

						var opposite := -_turned_dir_sign
						if opposite == 0:
							opposite = -1 if randi() % 2 == 0 else 1

						direction = direction.rotated(opposite * deg_to_rad(turn_degrees))
						_step_dir = direction.normalized()
						rotation = direction.angle()

						_turned_dir_sign = opposite
					else:
						_step_remaining = 0.0
				else:
					_just_turned = true
					_turn_attempts = 1

					var turn_sign: int
					if LevelState.curr_lvl == 3:
						turn_sign = _choose_turn_toward_gold()
					else:
						turn_sign = 1 if randi() % 2 == 0 else -1

					direction = direction.rotated(turn_sign * deg_to_rad(turn_degrees))
					_step_dir = direction.normalized()
					rotation = direction.angle()

					_turned_dir_sign = turn_sign
			else:
				_step_remaining = 0.0

		if _step_remaining <= 0.0:
			_step_active = false
			velocity = Vector2.ZERO
			step_finished.emit()
			check_done_cond(true)
			return

	velocity = Vector2.ZERO


func check_done_cond(in_while) -> void:
	var t := check_tile_ahead()
	
	if LevelState.curr_lvl < 4:
		if t == "gold":
			gold_reached.emit()
		elif t == "stone" or t.begins_with("wall"):
			blocked.emit()
		else:
			if not in_while:
				onr.emit()
	elif LevelState.curr_lvl == 4:
		
		if LevelState.lvl4_gold == 0:
			gold_reached.emit()


func move_step(distance: float) -> void:
	if auto_move or _step_active:
		return

	_step_dir = direction.normalized()
	_step_remaining = absf(distance)
	_step_active = true
	_just_turned = false
	_turned_dir_sign = 0
	_turn_attempts = 0

	await step_finished
	
func move_stop() -> void:
	_step_active = false
	_step_remaining = 0.0


func reset_pos() -> void:
	position = Vector2.ZERO

	direction = Vector2.RIGHT
	_step_dir = Vector2.RIGHT
	rotation = 0.0

	_step_active = false
	_step_remaining = 0.0
	_just_turned = false
	_turned_dir_sign = 0
	_turn_attempts = 0
	velocity = Vector2.ZERO


func turn_left() -> void:
	direction = direction.rotated(-deg_to_rad(turn_degrees))
	_step_dir = direction.normalized()
	rotation = direction.angle()


func turn_right() -> void:
	direction = direction.rotated(deg_to_rad(turn_degrees))
	_step_dir = direction.normalized()
	rotation = direction.angle()


func _choose_turn_toward_gold() -> int:
	var my_cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var to_gold: Vector2 = Vector2(gold_cell - my_cell)
	if to_gold.length() < 0.001:
		return -1 if randi() % 2 == 0 else 1

	to_gold = to_gold.normalized()

	var left_dir: Vector2 = _step_dir.rotated(-deg_to_rad(turn_degrees)).normalized()
	var right_dir: Vector2 = _step_dir.rotated(deg_to_rad(turn_degrees)).normalized()

	var left_score: float = left_dir.dot(to_gold)
	var right_score: float = right_dir.dot(to_gold)

	var best := 1 if right_score > left_score else -1

	if randf() < gold_turn_bias:
		return best

	return -1 if randi() % 2 == 0 else 1


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
