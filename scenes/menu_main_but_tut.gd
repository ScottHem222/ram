extends Button

@onready var main_menu = $"../../MainLayer"
@onready var tut_menu = $"../../TutLayer"


func _ready():
	pressed.connect(_button_pressed)
	
	
func _button_pressed():
	main_menu.visible = false
	tut_menu.visible = true
	
