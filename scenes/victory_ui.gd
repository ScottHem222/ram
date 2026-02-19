extends Control


signal rtm

func _ready() -> void:
	$msg.text = ""
	$Menu.pressed.connect(reset_pressed)
	
	if LevelState.curr_lvl == 1:
		$msg.text = "You now know how to use a block to call a specific function of the Robot!"
	elif LevelState.curr_lvl == 2:
		$msg.text = "You now know how to call robot functions conditionally with an IF block"
	elif LevelState.curr_lvl == 3:
		$msg.text = "You now know how to use a WHILE loop to repeat things until its condition is met"
	elif LevelState.curr_lvl == 4:
		$msg.text = "You know how how to use a FOR loop to repate things a specific amount of times"
		
	
func reset_pressed():
	var curr = LevelState.levels_done
	if LevelState.curr_lvl == 1:
		if curr == 0:
			LevelState.levels_done += 1
	elif LevelState.curr_lvl == 2:
		if curr == 1:
			LevelState.levels_done += 1
	elif LevelState.curr_lvl == 3:
		if curr == 2:
			LevelState.levels_done += 1	
	elif LevelState.curr_lvl == 4:
		if curr == 3:
			LevelState.levels_done += 1
	
	rtm.emit()
