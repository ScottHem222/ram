extends Node2D

var level = 1

var move_blocks: int
var turn_blocks: int
var if_blocks: int
var while_blocks: int
var for_blocks: int
var a_move_blocks: int

signal block_count_changed
var error_ui_scene := preload("res://scenes/ErrorUI.tscn")
var fail_ui: Node = null
var win_ui_scene := preload("res://scenes/VictoryUI.tscn")
var t1_scene := preload("res://scenes/t_1.tscn")
var t3_scene := preload("res://scenes/t_3.tscn")
var t4_scene := preload("res://scenes/t_4.tscn")
var l_scene := preload("res://gen_lvl.tscn")
var robot: Node = null
var t1: Node = null

@onready var game_UI = $GameUILayer/level_UI

func _ready():
	
	level = LevelState.curr_lvl
	print("level: ", level)
	game_UI.setup_block_buttons()
	
	if level == 1:
		move_blocks = 5
		turn_blocks = 5
		if_blocks = 1
		while_blocks = 0
		for_blocks = 0
		a_move_blocks = 0
		t1 = t1_scene.instantiate()
		add_child(t1)
		t1.randomise_ores()
		robot = t1.get_node("Robot")
	
	if level == 2:
		move_blocks = 1
		turn_blocks = 0
		if_blocks = 1
		while_blocks = 0
		for_blocks = 0
		a_move_blocks = 0
		t1 = t1_scene.instantiate()
		add_child(t1)
		t1.randomise_ores()
		robot = t1.get_node("Robot")
		
	if level == 3:
		move_blocks = 0
		turn_blocks = 0
		if_blocks = 1
		while_blocks = 1
		for_blocks = 0
		a_move_blocks = 0
		t1 = t3_scene.instantiate()
		add_child(t1)
		#t1.ranomise_ores()
		robot = t1.get_node("Robot")
		
	if level == 4:
		move_blocks = 0
		turn_blocks = 0
		if_blocks = 1
		while_blocks = 0
		for_blocks = 1
		a_move_blocks = 1
		
		t1 = t4_scene.instantiate()
		add_child(t1)
		robot = t1.get_node("Robot")
		LevelState.lvl4_gold = 11
		
	if level == 5:
		move_blocks = 0
		turn_blocks = 0
		if_blocks = 5
		while_blocks = 0
		for_blocks = 5
		a_move_blocks = 1
		
		t1 = l_scene.instantiate()
		add_child(t1)
		robot = t1.get_node("Robot")
		robot.update_metrics.connect(update_UI_score_l5)
		
		t1.generate_inside_from_boundary()
		
		
	emit_signal("block_count_changed")
	
	$BeginLayer.visible = true
	
	if LevelState.curr_lvl != 5:
		robot.onr.connect(fail_onr)
		robot.gem_mined.connect(fail_t4_non_gold)
		
	robot.blocked.connect(fail_blocked)
	robot.gold_reached.connect(level_won)
	
	game_UI.rtm_ui.connect(return_to_menu)
	game_UI.reset_lvl.connect(robot.reset_pos)	
	
func _show_fail(err: int) -> void:
	# prevent duplicates
	if fail_ui != null and is_instance_valid(fail_ui):
		return

	fail_ui = error_ui_scene.instantiate()
	$FailLayer.add_child(fail_ui)

	fail_ui.err_type = err
	fail_ui.update()
	fail_ui.error_reset.connect(reset_on_fail)

func fail_onr() -> void:
	_show_fail(1)

func fail_blocked() -> void:
	_show_fail(2)
	
func fail_t4_non_gold() -> void:
	_show_fail(3)

func level_won():
	var win_ui = win_ui_scene.instantiate()
	$FailLayer.add_child(win_ui)
	win_ui.rtm.connect(return_to_menu)
	
func set_home():
	robot.gold_cell = Vector2(0,0)
	
	
func reset_on_fail() -> void:
	if fail_ui != null and is_instance_valid(fail_ui):
		fail_ui.queue_free()
	fail_ui = null

	robot.reset_pos()
	game_UI.enable_buttons()
	
	if LevelState.curr_lvl == 4:
		LevelState.lvl4_gold = 12
		
		
func update_UI_score_l5():
	game_UI.update_goal_msg()
	
	
func return_to_menu():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
	
	
