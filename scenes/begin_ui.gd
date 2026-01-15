extends Control

var curr_lvl = 1

var t1 := [
	"> Welcome to your new job remote controling our mining robot",
    "> Unfortunately, your predecesor left no documentation on how anything works, so we're gonna have
	to figure that out together in the simulator.",
	"> Lets start by moving the robot to the gold deposit",
	"> Good luck!",
	"(Key Programming Concept/s: Function Calls and Basic IF statements)"
]

@export var line_delay := 2.5 # seconds between lines

func _ready():
	$Button.disabled = true
	play_init_msg()
	

func set_lvl(new):
	curr_lvl = new


func play_init_msg():
	
	if curr_lvl == 1:
		for line in t1:
			$LevelMsg.text += line + "\n"
			await get_tree().create_timer(line_delay).timeout
			
	
	$Button.disabled = false
	
