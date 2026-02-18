extends CharacterBody2D

# -------------------------
# CONFIG
# -------------------------
@export var speed: float = 200.0
@export var turn_degrees: float = 90.0
@export var tile_size: float = 64.0

@export var tilemap_path: NodePath
@onready var tilemap: TileMapLayer = get_node(tilemap_path)

# Mining replacement tile (set in inspector)
@export var mine_delay: float = 2.0
@export var tunnel_source_id: int = 0
@export var tunnel_atlas_coords: Vector2i = Vector2i(4, 0)
@export var tunnel_alt: int = 0

# Optional: bias turning toward a known gold cell (for specific levels)
@export var gold_cell: Vector2i = Vector2i.ZERO
@export var gold_turn_bias: float = 0.75

# Tile probing (used by ahead/left/right checks)
@export var probe_dist: float = 0.45 # slightly less than half a tile

var _stuck_frames: int = 0
const STUCK_LIMIT := 8   # frames before we consider robot stuck

# -------------------------
# SIGNALS / STATE
# -------------------------
signal onr()
signal blocked()
signal gold_reached()

signal step_finished

var auto_move: bool = false
var turn: bool = false          # "if obstacle then turn" rule from blocks
var mine_gold: bool = false     # set true by your for-block logic

var direction: Vector2 = Vector2.RIGHT

# step execution
var _step_active: bool = false
var _step_remaining: float = 0.0
var _step_dir: Vector2 = Vector2.RIGHT
var _step_infinite: bool = false

# turning while blocked
var _just_turned: bool = false
var _turned_dir_sign: int = 0   # -1 left, +1 right
var _turn_attempts: int = 0     # try up to 2 directions when blocked
var _turned_this_frame: bool = false

# mining
var _mining: bool = false

# UI scanner + tooltip
@export var scanner_cell: Vector2i = Vector2i(22, 0)
@onready var scanner_tilemap: TileMapLayer = get_node("/root/Node2D/GameUILayer/level_UI/ScannerTile")
@onready var scanner_label: Label = get_node("/root/Node2D/GameUILayer/level_UI/scanner")

@onready var hover_area: Area2D = $HoverArea
var tooltip_panel
var tooltip_label
var tt_methods_1: Array[String] = ["Move()", "Turn([Left/Right])", "Stop()", "Mine()"]

@onready var ray: RayCast2D = $ray_fw


# -------------------------
# LIFECYCLE
# -------------------------
func _ready() -> void:
	add_to_group("robot")

	tooltip_panel = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip")
	tooltip_label = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip/Text")
	hover_area.mouse_entered.connect(_on_robot_mouse_entered)
	hover_area.mouse_exited.connect(_on_robot_mouse_exited)
	tooltip_panel.visible = false
	


func _process(_delta: float) -> void:
	if tooltip_panel and tooltip_panel.visible:
		var screen_pos := get_viewport().get_canvas_transform() * global_position
		tooltip_panel.position = screen_pos + Vector2(40, -20)


func _physics_process(delta: float) -> void:
	if auto_move:
		_auto_move_tick(delta)
		return

	if _step_active:
		_step_tick(delta)
	else:
		velocity = Vector2.ZERO


# -------------------------
# AUTO MOVE
# -------------------------
func _auto_move_tick(_delta: float) -> void:
	if turn and ray.is_colliding():
		_turn_random()

	_apply_direction_visuals()
	velocity = direction.normalized() * speed
	move_and_slide()


# -------------------------
# STEP MOVE
# -------------------------
func move_step(distance: float) -> void:
	if auto_move or _step_active:
		return

	_stuck_frames = 0
	_step_active = true
	_step_infinite = false
	_step_remaining = absf(distance)

	_set_step_dir_from_direction()
	_reset_turn_block_state()
	await step_finished


func move_step_infinite() -> void:
	if auto_move or _step_active:
		return

	_stuck_frames = 0
	_step_active = true
	_step_infinite = true
	_step_remaining = INF

	_set_step_dir_from_direction()
	_reset_turn_block_state()
	await step_finished


func _step_tick(delta: float) -> void:
	_turned_this_frame = false

	# Pause movement while mining
	if _mining:
		velocity = Vector2.ZERO
		move_and_slide()
		update_scanner_tile()
		return

	_apply_step_visuals()

	# Move using move_and_slide so it matches your auto movement feel
	var step_dist: float = minf(speed * delta, _step_remaining)
	var safe_delta: float = maxf(delta, 0.000001)
	velocity = _step_dir * (step_dist / safe_delta)
	move_and_slide()
	update_scanner_tile()

	# early stop behavior
	# - normal levels: reaching gold ends the run
	# - level 4 mining: gold ahead should stop so we can mine it
	if LevelState.curr_lvl == 4 and mine_gold:
		if _is_gold_ahead_grid():
			_step_remaining = 0.0
			await _mine_tick() # mine the gold we stopped in front of
			_finish_step(true)
			return
	else:
		# original reach-gold behavior
		var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
		var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
		var ahead_cell := cell + step

		var ahead_type := _tile_type_at(ahead_cell)
		var here_type := _tile_type_at(cell)

		if here_type == "gold" or ahead_type == "gold":
			_step_remaining = 0.0
			_finish_step(true)
			return

	# Mining check (does not end the step)
	await _mine_tick()
	if _mining:
		return

	# Consume distance actually moved
	var moved := get_last_motion().length()
	if not _step_infinite:
		_step_remaining -= moved

	# If we moved, allow turning again if we get blocked later
	if moved > 0.001:
		_reset_turn_block_state()
		_stuck_frames = 0
	else:
		_stuck_frames += 1

	# If obstacle ahead, handle turn/stop ONCE per frame
	if _is_obstacle_ahead():
		_handle_turn_if_blocked()
		if _turned_this_frame:
			_stuck_frames = 0
			return

	# ---- STUCK WATCHDOG (only if we did NOT turn this frame) ----
	if _stuck_frames >= STUCK_LIMIT:
		print("Robot stuck → forcing turn once")
		turn_left()
		_turned_this_frame = true
		_stuck_frames = 0
		_reset_turn_block_state()
		return

	# Finish step if no distance left (or forced to 0)
	if not _step_infinite and _step_remaining <= 0.0:
		_finish_step(true)
		return

	# If infinite, only finish when something forces remaining to 0
	if _step_infinite and _step_remaining <= 0.0:
		_finish_step(true)
		return


func _finish_step(in_while: bool) -> void:
	_step_active = false
	velocity = Vector2.ZERO
	step_finished.emit()
	check_done_cond(in_while)


func _is_obstacle_ahead() -> bool:
	# collision OR obstacle tile counts as "blocked"
	if _hit_ahead():
		return true
	var t := check_tile_ahead()
	return t == "" or t == "stone" or t.begins_with("wall")
	

func _is_gold_ahead_grid() -> bool:
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step
	return _tile_type_at(ahead_cell) == "gold"


func _handle_turn_if_blocked() -> void:
	if not turn:
		_step_remaining = 0.0
		return

	# try up to 2 directions when stuck (prevents corners lock)
	if not _just_turned:
		_just_turned = true
		_turn_attempts = 1

		@warning_ignore("shadowed_global_identifier")
		var sign := _choose_turn_sign()
		_apply_turn_sign(sign)
		_turned_dir_sign = sign
		_turned_this_frame = true
		return

	# already turned once this block; try the opposite once
	if _turn_attempts < 2:
		_turn_attempts += 1
		var opposite := -_turned_dir_sign
		if opposite == 0:
			opposite = -1 if randi() % 2 == 0 else 1

		_apply_turn_sign(opposite)
		_turned_dir_sign = opposite
		_turned_this_frame = true
		return

	# tried both directions, give up this step
	_step_remaining = 0.0


# -------------------------
# TURNING
# -------------------------
func _choose_turn_sign() -> int:
	if gold_cell != Vector2i.ZERO:
		return _choose_turn_toward_gold()
	return 1 if randi() % 2 == 0 else -1


@warning_ignore("shadowed_global_identifier")
func _apply_turn_sign(sign: int) -> void:
	direction = direction.rotated(sign * deg_to_rad(turn_degrees))
	_set_step_dir_from_direction()
	_apply_direction_visuals()


func _turn_random() -> void:
	@warning_ignore("shadowed_global_identifier")
	var sign := 1 if randi() % 2 == 0 else -1
	_apply_turn_sign(sign)


func turn_left() -> void:
	_apply_turn_sign(-1)


func turn_right() -> void:
	_apply_turn_sign(1)


func _reset_turn_block_state() -> void:
	_just_turned = false
	_turned_dir_sign = 0
	_turn_attempts = 0


# -------------------------
# MINING (ahead/left/right)
# -------------------------
func _mine_tick() -> void:
	if not mine_gold or _mining:
		return

	var target := _adjacent_gold_cell()
	if target.x > 100000:
		return

	_mining = true
	velocity = Vector2.ZERO

	await get_tree().create_timer(mine_delay).timeout

	_set_cell_to_tunnel(target)

	if LevelState.curr_lvl == 4 and LevelState.lvl4_gold > 0:
		LevelState.lvl4_gold -= 1

	_mining = false


func _set_cell_to_tunnel(cell: Vector2i) -> void:
	tilemap.set_cell(cell, tunnel_source_id, tunnel_atlas_coords, tunnel_alt)


func _adjacent_gold_cell() -> Vector2i:
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step

	if _tile_type_at(ahead_cell) == "gold":
		return ahead_cell

	return Vector2i(999999, 999999)


################
#Tile checking
#################
func _cell_under_robot() -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(global_position))


func _cell_in_direction(dir: Vector2) -> Vector2i:
	# Probe from robot center slightly into the next tile
	var probe_point := global_position + dir.normalized() * (tile_size * probe_dist)
	return tilemap.local_to_map(tilemap.to_local(probe_point))


func _tile_type_at(cell: Vector2i) -> String:
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return ""
	if td.has_custom_data("type"):
		return String(td.get_custom_data("type"))
	return ""


func check_tile_ahead() -> String:
	return _tile_type_at(_cell_in_direction(_step_dir))


func check_tile_left() -> String:
	return _tile_type_at(_cell_in_direction(_step_dir.rotated(-PI / 2.0)))


func check_tile_right() -> String:
	return _tile_type_at(_cell_in_direction(_step_dir.rotated(PI / 2.0)))


func _is_gold_here_or_ahead() -> bool:
	var here := _tile_type_at(_cell_under_robot())
	var ahead := check_tile_ahead()
	return here == "gold" or ahead == "gold"


func _hit_ahead() -> bool:
	for j in range(get_slide_collision_count()):
		var c := get_slide_collision(j)
		if c.get_normal().dot(_step_dir) < -0.7:
			return true
	return false
	
func check_tile_here() -> String:
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return ""
	if td.has_custom_data("type"):
		return String(td.get_custom_data("type"))
	return ""


# -------------------------
# VISUALS
# -------------------------
func _set_step_dir_from_direction() -> void:
	_step_dir = direction.normalized()


func _apply_direction_visuals() -> void:
	rotation = direction.angle()


func _apply_step_visuals() -> void:
	rotation = _step_dir.angle()


# -------------------------
# SCANNER UI
# -------------------------
func update_scanner_tile() -> void:
	if scanner_tilemap == null or tilemap == null:
		return

	# scanner uses a simple grid step (one tile in facing direction)
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step

	var source_id: int = tilemap.get_cell_source_id(ahead_cell)
	if source_id == -1:
		scanner_tilemap.erase_cell(scanner_cell)
		scanner_label.text = "SCANNER\nType: Empty\nValue: ?"
		return

	var atlas: Vector2i = tilemap.get_cell_atlas_coords(ahead_cell)
	var alt: int = tilemap.get_cell_alternative_tile(ahead_cell)
	scanner_tilemap.set_cell(scanner_cell, source_id, atlas, alt)

	var tile_name := _tile_type_at(ahead_cell)

	if tile_name == "tunnel":
		scanner_label.text = "SCANNER\nType: Tunnel\nValue: 0"
	elif tile_name.begins_with("wall") or tile_name == "stone":
		scanner_label.text = "SCANNER\nType: Obstacle\nValue: -1"
	elif tile_name.begins_with("gem"):
		scanner_label.text = "SCANNER\nType: Gem\nValue: 20"
	elif tile_name == "gold":
		scanner_label.text = "SCANNER\nType: Gold\nValue: 25"
	else:
		scanner_label.text = "SCANNER\nType: Unknown\nValue: ?"


# -------------------------
# LEVEL END CONDITIONS
# -------------------------
func check_done_cond(in_while: bool) -> void:
	# Level 4 win condition is "all gold mined"
	if LevelState.curr_lvl == 4:
		if LevelState.lvl4_gold <= 0:
			gold_reached.emit()
		return
	
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step
	
	var here = _tile_type_at(ahead_cell)

	if here == "gold":
		gold_reached.emit()
		return
	elif here == "stone" or here.begins_with("wall"):
		blocked.emit()
		return

	if not in_while:
		onr.emit()


# -------------------------
# RESET / STOP
# -------------------------
func move_stop() -> void:
	_step_active = false
	_step_infinite = false
	_step_remaining = 0.0


func reset_pos() -> void:
	position = Vector2.ZERO

	direction = Vector2.RIGHT
	_set_step_dir_from_direction()
	rotation = 0.0

	_step_active = false
	_step_infinite = false
	_step_remaining = 0.0
	velocity = Vector2.ZERO

	_mining = false
	_reset_turn_block_state()


# -------------------------
# GOLD-BIAS TURN
# -------------------------
func _choose_turn_toward_gold() -> int:
	var my_cell: Vector2i = _cell_under_robot()
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


# -------------------------
# TOOLTIP
# -------------------------
func _on_robot_mouse_entered() -> void:
	tooltip_label.text = "Robot Functions:\n- " + "\n- ".join(tt_methods_1)
	tooltip_panel.visible = true


func _on_robot_mouse_exited() -> void:
	tooltip_panel.visible = false
