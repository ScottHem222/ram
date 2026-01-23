extends Button

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed():
	$"../../Tour1".visible = false
	$"../../Tour2".visible = true
