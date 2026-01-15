extends Control

# 1 - ONR, 2 - Stuck
var err_type = 1
var hint_msg = ""

signal error_reset

func _ready() -> void:
	$"../".visible = false
	$Again.pressed.connect(reset_pressed)
	
func update():
	
	$"../".visible = true
	
	if err_type == 1:
		$NotReached.visible = true
		$Stuck.visible = false
		hint_msg = "Objective not reached, change how far the robot will move"
	elif err_type == 2:
		$NotReached.visible = false
		$Stuck.visible = true
		hint_msg = "Robot is stuck on an obstacle, try using an IF block to avoid certain things"
		

func reset_pressed():
	error_reset.emit()
