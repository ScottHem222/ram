extends Button

@onready var bound_box := get_node("../BlockBoundBox")
@onready var robot := get_node("../../../../t_1/Robot")

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed():
	
	$"../..".disable_buttons()
	
	bound_box.run_blocks(robot)
	
	
