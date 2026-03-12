extends Button

@export var lvl: int

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed():
	LevelState.curr_lvl = lvl
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
