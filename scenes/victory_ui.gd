extends Control


signal rtm

func _ready() -> void:
	$msg.text = ""
	$Menu.pressed.connect(reset_pressed)
	
	if LevelState.curr_lvl == 1:
		$msg.text = "You now know how to use a block to call a specific function of the Robot!"
	elif LevelState.curr_lvl == 2:
		$msg.text = "You now know how to call robot functions conditionally with an IF block"
		
	
func reset_pressed():
	LevelState.levels_done += 1
	rtm.emit()
