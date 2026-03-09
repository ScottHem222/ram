extends Control

# 1 - ONR, 2 - Stuck
# 3 - lvl 4 non gold mined
var err_type = 1

signal error_reset


var l1_onr := [
	"> Move the robot further, the gold is 30 units away."
]

var l1_stuck := [
	"> Hover over the robot and see if we can use something to avoid the obstacles"
]

var l2_onr := [
	"> Move the robot further, the gold is 20 units away.",
	"> The robot turns also seem to be random so you might need to go further than that"
]

#stuck
var l2_stuck := [
	"> Use an IF block",
	"> Hovering over the robot lists what it can do",
	"> The scanner also shows the type of tile currently infront of the robot"
]

var l3_stuck := [
	"> Make sure you still have the Turn() condition from last time!",
	"> Drag it into the lower slot in the code section"
]

var l4_non_gold := [
	"> Mining obstacles or other ore types breaks the robot at the moment",
	"> Find a way to only mine Gold ore"
]


# L5 endless

var l5_stuck := [
	"> Use if statements to either mine whats blocking you or turn away from it"
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
		$exploded.visible = false
	elif err_type == 2:
		$NotReached.visible = false
		$Stuck.visible = true
		$exploded.visible = false
	elif err_type == 3:
		$NotReached.visible = false
		$Stuck.visible = false
		$exploded.visible = true

		
func reset_pressed():
	error_reset.emit()
	
func play_hint_msg():
	
	print("Err level: ", LevelState.curr_lvl)
	$msg.text = ""
	
	if LevelState.curr_lvl == 1:
		if err_type == 1:
			for line in l1_onr:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
		elif err_type == 2:
			for line in l1_stuck:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
	elif LevelState.curr_lvl == 2:
		if err_type == 1:
			for line in l2_onr:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
		elif err_type == 2:
			for line in l2_stuck:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
	elif LevelState.curr_lvl == 3:
		if err_type == 2:
			for line in l3_stuck:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
	elif LevelState.curr_lvl == 4:
		if err_type == 3:
			for line in l4_non_gold:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
	elif LevelState.curr_lvl == 5:
		if err_type == 2:
			for line in l5_stuck:
				$msg.text += line + "\n"
				await get_tree().create_timer(line_delay).timeout
				
				
			
			

			
