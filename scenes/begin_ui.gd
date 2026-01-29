extends Control

var curr_lvl = LevelState.curr_lvl

var t1 := [
	"> Welcome to your new job remote controling our mining robot",
    "> Unfortunately, your predecesor left no documentation on how anything works, so we're gonna have
	to figure that out together in the simulator.",
	"> Lets start by moving the robot to the gold deposit 20 units away",
	"> Good luck!",
	">",
	"(Key Programming Concept/s: Function Calls)"
]

var t2 := [
	"> Ok, turns out theres a better way to move our robot",
	"> Turning has now been automated.",
	"> But we only want to turn when we need to, which you need to figure out how to do",
	">",
	">(Key Programming Concept/s: IF Statements)"
]

var t3 := [
	"> Ok, lets try finding the gold again in a much larger mine.",
	"> We dont know exactly how far away it is this time, so try looping the movement",
	"> Make sure to still check for obstacles",
	">",
	"(Key Programming Concept/s: WHILE Loops)",
	"> TIP: If a loops condition is True, it will loop forever"
]

@export var line_delay := 2.5 # seconds between lines

func _ready():
	$Button.disabled = true
	play_init_msg()
	




func play_init_msg():
	
	if curr_lvl == 1:
		for line in t1:
			$LevelMsg.text += line + "\n"
			await get_tree().create_timer(line_delay).timeout
	elif curr_lvl == 2:
		for line in t2:
			$LevelMsg.text += line + "\n"
			await get_tree().create_timer(line_delay).timeout
	elif curr_lvl == 3:
		for line in t3:
			$LevelMsg.text += line + "\n"
			await get_tree().create_timer(line_delay).timeout
			
	
	$Button.disabled = false
	
