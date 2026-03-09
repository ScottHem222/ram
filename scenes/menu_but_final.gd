extends Button

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed():
	LevelState.curr_lvl = 5
	LevelState.lvl5_score = 0
	LevelState.lvl5_energy = 200
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
