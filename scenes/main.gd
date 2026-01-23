extends Node2D

var level = 1

var move_blocks: int
var turn_blocks: int
var if_blocks: int

signal block_count_changed
var error_ui_scene := preload("res://scenes/ErrorUI.tscn")
var win_ui_scene := preload("res://scenes/VictoryUI.tscn")
var t1_scene := preload("res://scenes/t_1.tscn")
var robot: Node = null
var t1: Node = null

@onready var game_UI = $GameUILayer/level_UI

func _ready():
	
	level = LevelState.curr_lvl
	
	if level == 1:
		move_blocks = 5
		turn_blocks = 5
		if_blocks = 1
		t1 = t1_scene.instantiate()
		add_child(t1)
		robot = t1.get_node("Robot")
	
	if level == 2:
		move_blocks = 1
		turn_blocks = 0
		if_blocks = 1
		t1 = t1_scene.instantiate()
		add_child(t1)
		robot = t1.get_node("Robot")
		
	emit_signal("block_count_changed")
	
	$BeginLayer/beginUI.set_lvl(level)
	$BeginLayer.visible = true
	
	robot.onr.connect(fail_onr)
	robot.blocked.connect(fail_blocked)
	robot.gold_reached.connect(level_won)

func fail_onr():
	var error_ui = error_ui_scene.instantiate()
	$FailLayer.add_child(error_ui)
	error_ui.err_type = 1
	error_ui.update()
	error_ui.error_reset.connect(reset_on_fail)
	
func fail_blocked():
	var error_ui = error_ui_scene.instantiate()
	$FailLayer.add_child(error_ui)
	error_ui.err_type = 2
	error_ui.update()
	error_ui.error_reset.connect(reset_on_fail)

func level_won():
	var win_ui = win_ui_scene.instantiate()
	$FailLayer.add_child(win_ui)
	win_ui.rtm.connect(return_to_menu)
	
	
func reset_on_fail():
	robot.reset_pos()
	game_UI.enable_buttons()
	
func return_to_menu():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
	
	
