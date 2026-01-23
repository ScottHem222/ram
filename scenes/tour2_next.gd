extends Button

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed():
	$"../../Tour2".visible = false
