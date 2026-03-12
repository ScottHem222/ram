extends Control

var curr_lvl = LevelState.curr_lvl

var t1 := [
	"> Welcome to your new job remote controling our mining robot",
    "> Unfortunately, your predecesor left no documentation on how anything works, so we're gonna have
	to figure that out together in the simulator.",
	"> Lets start by moving the robot to the Ore deposit 30 units away",
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
	"> Ok, lets try finding the ore again in a much larger mine.",
	"> We dont know exactly how far away it is this time, so try looping the movement",
	"> The robot has a property called NotAtGoal. This could be useful for the loop",
	"> Make sure to still check for obstacles",
	">",
	"(Key Programming Concept/s: WHILE Loops)"
]

var t4 := [
	"> All of the code for the movement we made previously is now contained in the auto-move block!",
	"> Time to actually mine something with our robot.",
	"> We need to mine all of one of the ore types in the mine",
	"> However, only one type doesent result in the robot blowing up",
	"> Try and use the mine function of the robot FOR each ore IN the mine and see what happens",
	"> ",
	"(Key Programming Concept/s: FOR Loops)"
]

var l5 := [
	"> Time to let you loose in the real mine.",
	"> The robot has a limited amount of energy until it needs recharged",
	"> Try and mine things that give us the most value!",
	"> Tip: Just move around to work out the value of different things, then reset" 
]

@export var line_delay := 2.5 

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
	elif curr_lvl == 4:
		for line in t4:
			$LevelMsg.text += line + "\n"
			await get_tree().create_timer(line_delay).timeout
	elif curr_lvl == 5:
		for line in l5:
			$LevelMsg.text += line + "\n"
			await get_tree().create_timer(line_delay).timeout
			
	
	$Button.disabled = false
	
