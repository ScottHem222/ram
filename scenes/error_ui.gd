extends Control

# 1 - ONR, 2 - Stuck
var err_type = 1

signal error_reset

var h1_l1 := [
	"> Move the robot further, the gold is 20 units away."
]

var h1_l2 := [
	"> Move the robot further, the gold is 20 units away.",
	"> The robot turns also seem to be random so you might need to go further than that"
]

var h2_l1 := [
	"Hover over the robot to see what else it can do"
]

var h2_l2 := [
	"> Use an IF block",
	"> Hovering over the robot lists what it can do",
	"> The scanner also shows the type of tile currently infront of the robot"
]

@export var line_delay := 0.2 # seconds between lines

func _ready() -> void:
	$"../".visible = false
	$Again.pressed.connect(reset_pressed)
	
func update():
	
	$"../".visible = true
	
	if err_type == 1:
		$NotReached.visible = true
		$Stuck.visible = false
	elif err_type == 2:
		$NotReached.visible = false
		$Stuck.visible = true

		
func reset_pressed():
	error_reset.emit()
	
func play_hint_msg():
	
	if LevelState.curr_lvl == 1:
		if err_type == 1:
			for line in h1_l1:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
		elif err_type == 2:
			for line in h2_l1:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
	elif LevelState.curr_lvl == 2:
		if err_type == 1:
			for line in h1_l2:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
		elif err_type == 2:
			for line in h2_l2:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
				
			
			

			
