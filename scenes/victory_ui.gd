extends Control


signal rtm

func _ready() -> void:
	$Menu.pressed.connect(reset_pressed)
	
func reset_pressed():
	LevelState.levels_done += 1
	rtm.emit()
