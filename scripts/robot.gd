extends CharacterBody2D

# -------------------------
# CONFIG
# -------------------------
@export var speed: float = 200.0
@export var turn_degrees: float = 90.0
@export var tile_size: float = 64.0

@export var tilemap_path: NodePath
var tilemap: TileMapLayer 

# Mining replacement tile (set in inspector)
@export var mine_delay: float = 2.0
@export var tunnel_source_id: int = 0
@export var tunnel_atlas_coords: Vector2i = Vector2i(4, 0)
@export var tunnel_alt: int = 0

# Optional: bias turning toward a known gold cell (for specific levels)
@export var gold_cell: Vector2i = Vector2i.ZERO
@export var gold_turn_bias: float = 0.75

var _stuck_frames: int = 0
const STUCK_LIMIT := 8

# debug dot for "ahead" check (grid-based, same as scanner)
@export var show_probe_debug: bool = true
var debug_probe_point: Vector2 = Vector2.ZERO

#level 4
var _l4_start = Vector2i.ZERO
var _l4_left_start = false

# -------------------------
# SIGNALS / STATE
# -------------------------
signal onr()
signal blocked()
signal gold_reached()
signal step_finished
signal gem_mined()
signal return_home()

var auto_move: bool = false
var turn: bool = false
var mine_gold: bool = false
var mine_ore: bool = false
var mine_obstacles: bool = false

var direction: Vector2 = Vector2.RIGHT

# step execution
var _step_active: bool = false
var _step_remaining: float = 0.0
var _step_dir: Vector2 = Vector2.RIGHT
var _step_infinite: bool = false

# turning while blocked
var _just_turned: bool = false
var _turned_dir_sign: int = 0
var _turn_attempts: int = 0
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
var tt_methods_12: Array[String] = ["Move()", "Turn() (Left/Right)"]
var tt_methods_3: Array[String] = ["Move()", "Turn() (Left/Right)", "NotAtGoal: True"]
var tt_methods_4: Array[String] = ["Move()", "Turn() (Left/Right)", "Mine()"]

@onready var ray: RayCast2D = $ray_fw


# -------------------------
# LIFECYCLE
# -------------------------
func _ready() -> void:
	add_to_group("robot")
	
	tilemap = get_node(tilemap_path)
	_snap_to_grid()

	tooltip_panel = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip")
	tooltip_label = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip/Text")
	hover_area.mouse_entered.connect(_on_robot_mouse_entered)
	hover_area.mouse_exited.connect(_on_robot_mouse_exited)
	tooltip_panel.visible = false

		
	_l4_start = _cell_under_robot()


func _process(_delta: float) -> void:
	if tooltip_panel and tooltip_panel.visible:
		var screen_pos := get_viewport().get_canvas_transform() * global_position
		tooltip_panel.position = screen_pos + Vector2(40, -20)


func _physics_process(delta: float) -> void:
	
	if LevelState.curr_lvl == 4:
		var c = _cell_under_robot()
		if c != _l4_start:
			_l4_left_start = true
	
	if auto_move:
		_auto_move_tick(delta)
		return

	if _step_active:
		_step_tick(delta)
	else:
		velocity = Vector2.ZERO

"""
# -------------------------
# DEBUG DRAW
# -------------------------
func _draw() -> void:
	if show_probe_debug and debug_probe_point != Vector2.ZERO:
		draw_circle(to_local(debug_probe_point), 6.0, Color.RED)


func _update_debug_ahead_point(ahead_cell: Vector2i) -> void:
	if not show_probe_debug or tilemap == null:
		return

	# TileMapLayer map_to_local gives local pos of the cell (usually top-left).
	# Add half-tile to show center.
	var local := tilemap.map_to_local(ahead_cell) + Vector2(tile_size * 0.5, tile_size * 0.5)
	debug_probe_point = tilemap.to_global(local)
	queue_redraw()
"""

# -------------------------
# AUTO MOVE
# -------------------------
func _auto_move_tick(_delta: float) -> void:
	# level 4: stop + mine when gold is 1 tile ahead, then resume
	if LevelState.curr_lvl == 4 and mine_gold and not _mining:
		var cell := _cell_under_robot()
		var ahead_cell := _cell_ahead_from(cell)
		#_update_debug_ahead_point(ahead_cell)

		if _tile_type_at(ahead_cell) == "gold":
			velocity = Vector2.ZERO
			move_and_slide()
			await _mine_tick()
			return

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

	# ---- GRID-BASED tile checks (same as scanner) ----
	var cell := _cell_under_robot()
	var ahead_cell := _cell_ahead_from(cell)
	#_update_debug_ahead_point(ahead_cell)

	var here_type := _tile_type_at(cell)
	var ahead_type := _tile_type_at(ahead_cell)

	# early stop behavior:
	# - level 4 mining: stop when GOLD is ahead (so you mine it)
	# - other levels: stop when GOLD is here OR ahead (reach gold)
	if LevelState.curr_lvl == 4 and mine_gold:
		if ahead_type == "gold":
			# stop in front of gold, mine it, then keep going
			velocity = Vector2.ZERO
			move_and_slide()
			await _mine_tick() 
			_reset_turn_block_state()
			_stuck_frames = 0
			return
	else:
		if here_type == "gold" or ahead_type == "gold" or here_type.begins_with("gem") or ahead_type.begins_with("gem"):
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
	if _is_obstacle_type(ahead_type) or _hit_ahead():
		_handle_turn_if_blocked()
		if _turned_this_frame:
			_stuck_frames = 0
			return

	# ---- STUCK WATCHDOG ----
	if _stuck_frames >= STUCK_LIMIT:
		turn_left()
		_turned_this_frame = true
		_stuck_frames = 0
		_reset_turn_block_state()
		return
		
	# return home
	if LevelState.lvl4_gold == 0:
		return_home.emit()

	# Finish step if no distance left (or forced to 0)
	if not _step_infinite and _step_remaining <= 0.0:
		_finish_step(true)
		return

	if _step_infinite and _step_remaining <= 0.0:
		_finish_step(true)
		return


func _finish_step(in_while: bool) -> void:
	_step_active = false
	velocity = Vector2.ZERO
	step_finished.emit()
	check_done_cond(in_while)


func _handle_turn_if_blocked() -> void:
	if not turn:
		_step_remaining = 0.0
		return

	if not _just_turned:
		_just_turned = true
		_turn_attempts = 1

		var tsign := _choose_turn_sign()
		_apply_turn_sign(tsign)
		_turned_dir_sign = tsign
		_turned_this_frame = true
		return

	if _turn_attempts < 2:
		_turn_attempts += 1
		var opposite := -_turned_dir_sign
		if opposite == 0:
			opposite = -1 if randi() % 2 == 0 else 1

		_apply_turn_sign(opposite)
		_turned_dir_sign = opposite
		_turned_this_frame = true
		return

	_step_remaining = 0.0


# -------------------------
# TURNING
# -------------------------
func _choose_turn_sign() -> int:
	if gold_cell != Vector2i.ZERO:
		return _choose_turn_toward_gold()
	return 1 if randi() % 2 == 0 else -1


func _apply_turn_sign(tsign: int) -> void:
	direction = direction.rotated(tsign * deg_to_rad(turn_degrees))
	_set_step_dir_from_direction()
	_apply_direction_visuals()


func _turn_random() -> void:
	var tsign := 1 if randi() % 2 == 0 else -1
	_apply_turn_sign(tsign)


func turn_left() -> void:
	_apply_turn_sign(-1)


func turn_right() -> void:
	_apply_turn_sign(1)


func _reset_turn_block_state() -> void:
	_just_turned = false
	_turned_dir_sign = 0
	_turn_attempts = 0


# -------------------------
# MINING (ahead only, grid)
# -------------------------
func _mine_tick() -> void:
	
	if (not mine_gold and not mine_ore and not mine_obstacles) or _mining:
		return

	var cell := _cell_under_robot()
	var ahead_cell := _cell_ahead_from(cell)
	
	var cell_type = _tile_type_at(ahead_cell)
	
	var is_gold = cell_type == "gold"
	var is_gem = cell_type.begins_with("gem")
	var is_ob = cell_type == "stone" or cell_type.begins_with("wall")
	# Only mine if the tile is mineable AND the correct flag is enabled
	if is_gold and not mine_gold:
		return
	if is_gem and not mine_ore:
		return
	if is_ob and not mine_obstacles:
		return
	if not is_gold and not is_gem and not is_ob:
		return

	if is_ob:
		move_stop()
		gem_mined.emit()
		
	_mining = true
	velocity = Vector2.ZERO

	await get_tree().create_timer(mine_delay).timeout
	_set_cell_to_tunnel(ahead_cell)

	if LevelState.curr_lvl == 4 and LevelState.lvl4_gold > 0 and cell_type == "gold":
		LevelState.lvl4_gold -= 1
		check_done_cond(false)
	
	if LevelState.curr_lvl == 4 and cell_type.begins_with("gem"):
		move_stop()
		gem_mined.emit()	
		
		
	_mining = false


func _set_cell_to_tunnel(cell: Vector2i) -> void:
	tilemap.set_cell(cell, tunnel_source_id, tunnel_atlas_coords, tunnel_alt)


# -------------------------
# TILE (grid-based, same as scanner)
# -------------------------
func _cell_under_robot() -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(global_position))


func _step_vec() -> Vector2i:
	return _grid_step_from_dir(_step_dir)


func _cell_ahead_from(base: Vector2i) -> Vector2i:
	return base + _step_vec()


func _tile_type_at(cell: Vector2i) -> String:
	var td: TileData = tilemap.get_cell_tile_data(cell)
	if td == null:
		return ""
	if td.has_custom_data("type"):
		return String(td.get_custom_data("type"))
	return ""


func _is_obstacle_type(t: String) -> bool:
	return t == "stone" or t.begins_with("wall")


func check_tile_here() -> String:
	return _tile_type_at(_cell_under_robot())


func check_tile_ahead() -> String:
	var cell := _cell_under_robot()
	return _tile_type_at(_cell_ahead_from(cell))


func check_tile_left() -> String:
	var cell := _cell_under_robot()
	var s := _step_vec()
	var left_step := Vector2i(-s.y, s.x)
	return _tile_type_at(cell + left_step)


func check_tile_right() -> String:
	var cell := _cell_under_robot()
	var s := _step_vec()
	var right_step := Vector2i(s.y, -s.x)
	return _tile_type_at(cell + right_step)


func _hit_ahead() -> bool:
	for j in range(get_slide_collision_count()):
		var c := get_slide_collision(j)
		if c.get_normal().dot(_step_dir) < -0.7:
			return true
	return false


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

	var cell := _cell_under_robot()
	var ahead_cell := _cell_ahead_from(cell)

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
		scanner_label.text = "SCANNER\nType: Obstacle\n"
	elif tile_name == "gem_blue":
		scanner_label.text = "SCANNER\nType: Ore (Cobalt)\n"
	elif tile_name == "gem_green":
		scanner_label.text = "SCANNER\nType: Ore (Uranium)\n"
	elif tile_name == "gem_pink":
		scanner_label.text = "SCANNER\nType: Ore (Copper)\n"
	elif tile_name == "gold":
		scanner_label.text = "SCANNER\nType: Ore (Gold)\n"
	else:
		scanner_label.text = "SCANNER\nType: Unknown\nValue: ?"


# -------------------------
# LEVEL END CONDITIONS 
# -------------------------
func check_done_cond(in_while: bool) -> void:
	#var c = _cell_under_robot()
	
	if LevelState.curr_lvl == 4:
		if LevelState.lvl4_gold <= 0: #and c == _l4_start and _l4_left_start:
			move_stop()
			gold_reached.emit()
		return

	var cell := _cell_under_robot()
	var ahead_cell := _cell_ahead_from(cell)

	var ahead := _tile_type_at(ahead_cell)
	var here := _tile_type_at(cell)

	if here == "gold" or ahead == "gold" or here.begins_with("gem") or ahead.begins_with("gem"):
		gold_reached.emit()
		return

	if _is_obstacle_type(ahead):
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
	
	if LevelState.curr_lvl == 4:
		LevelState.lvl4_gold = 11

func _snap_to_grid() -> void:
	var cell = tilemap.local_to_map(tilemap.to_local(global_position))
	global_position = tilemap.to_global(tilemap.map_to_local(cell))


# -------------------------
# GOLD-BIAS TURN
# -------------------------
func _choose_turn_toward_gold() -> int:
	var my_cell := _cell_under_robot()
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

# ----------------------
# Fix for tile detection
# ----------------------
func _grid_step_from_dir(dir: Vector2) -> Vector2i:
	var ax := absf(dir.x)
	var ay := absf(dir.y)

	if ax >= ay:
		return Vector2i(int(sign(dir.x)), 0)
	else:
		return Vector2i(0, int(sign(dir.y)))


# -------------------------
# TOOLTIP
# -------------------------
func _on_robot_mouse_entered() -> void:
	var methods
	match LevelState.curr_lvl:
		1: methods = tt_methods_12
		2: methods = tt_methods_12
		3: methods = tt_methods_3
		4: methods = tt_methods_4
	
	tooltip_label.text = "Robot Functions:\n- " + "\n- ".join(methods)
	tooltip_panel.visible = true


func _on_robot_mouse_exited() -> void:
	tooltip_panel.visible = false
