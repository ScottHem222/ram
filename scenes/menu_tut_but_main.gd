extends Button

@onready var main_menu = $"../../MainLayer"
@onready var tut_menu = $"../../TutLayer"


func _ready():
	pressed.connect(_button_pressed)
	
	
func _button_pressed():
	tut_menu.visible = false
	main_menu.visible = true

	
