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

# hover panel
@export var tooltip_panel_path: NodePath
@export var tooltip_label_path: NodePath
var tooltip_panel
var tooltip_label

@onready var hover_area: Area2D = $HoverArea

var tt_methods_1: Array[String] = [
	"Move()",
	"Turn()",
	"NotAtGoal"
]

#Scanning

@export var scanner_cell: Vector2i = Vector2i(22, 0)
@onready var scanner_tilemap: TileMapLayer = get_node("/root/Node2D/GameUILayer/level_UI/ScannerTile")
@onready var scanner_label: Label = get_node("/root/Node2D/GameUILayer/level_UI/scanner")



func _ready() -> void:
	tooltip_panel = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip")
	tooltip_label = get_node("/root/Node2D/GameUILayer/level_UI/RobotTooltip/Text")
	hover_area.mouse_entered.connect(_on_robot_mouse_entered)
	hover_area.mouse_exited.connect(_on_robot_mouse_exited)
	tooltip_panel.visible = false


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

	# cell under robot
	var cell: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))

	# one-tile step in facing direction
	var step := Vector2i(int(sign(_step_dir.x)), int(sign(_step_dir.y)))
	var ahead_cell := cell + step

	# read tile from LEVEL tilemap
	var source_id: int = tilemap.get_cell_source_id(ahead_cell)
	if source_id == -1:
		scanner_tilemap.erase_cell(scanner_cell) # empty
		return

	var atlas: Vector2i = tilemap.get_cell_atlas_coords(ahead_cell)
	var alt: int = tilemap.get_cell_alternative_tile(ahead_cell)

	# write same tile into UI scanner tilemap"
	scanner_tilemap.set_cell(scanner_cell, source_id, atlas, alt)
	
	var tile_name = check_tile_ahead()
	if tile_name == "tunnel":
		scanner_label.text = "SCANNER\nType: Tunnel\nValue: 0"
	elif tile_name.begins_with("wall") or tile_name == "stone":
		scanner_label.text = "SCANNER\nType: Obstacle\nValue: -1"
	elif tile_name.begins_with("gem") or tile_name == "gold":
		scanner_label.text = "SCANNER\nType: Valueable\nValue: 20"
	


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
		
		update_scanner_tile()

		var moved: float = get_last_motion().length()
		_step_remaining -= moved

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

			step_finished.emit()
			return

	velocity = Vector2.ZERO
	

func check_done_cond():
	# keep your original end-of-step behavior
	var t := check_tile_ahead()
	if t == "gold":
		gold_reached.emit()
	elif t == "stone" or t.begins_with("wall"):
		blocked.emit()
	else:
		onr.emit()


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

	direction = Vector2.RIGHT
	_step_dir = Vector2.RIGHT
	rotation = 0.0

	_step_active = false
	_step_remaining = 0.0
	_just_turned = false
	velocity = Vector2.ZERO
	
func turn_left() -> void:
	direction = direction.rotated(-deg_to_rad(turn_degrees))
	_step_dir = direction.normalized()
	rotation = direction.angle()

func turn_right() -> void:
	direction = direction.rotated(deg_to_rad(turn_degrees))
	_step_dir = direction.normalized()
	rotation = direction.angle()



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
	
