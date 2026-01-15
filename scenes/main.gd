extends Node2D

var level = 1

var move_blocks: int
var if_blocks: int

signal block_count_changed
var error_ui_scene := preload("res://scenes/ErrorUI.tscn")
var win_ui_scene := preload("res://scenes/VictoryUI.tscn")

@onready var robot = $t_1/Robot
@onready var game_UI = $GameUILayer/level_UI

func _ready():
	
	if level == 1:
		move_blocks = 1
		if_blocks = 1
		
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
	
	
	
