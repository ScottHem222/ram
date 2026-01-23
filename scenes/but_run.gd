extends Button

@onready var bound_box := get_node("../BlockBoundBox")
@onready var robot: Node = null

func _ready():
	pressed.connect(_button_pressed)
	
func _button_pressed():
	
	robot = get_node("../../../../t_1/Robot")
	$"../..".disable_buttons()
	$"../..".update_status("STATUS: Running", 1)
	
	await bound_box.run_blocks(robot)
	
	$"../..".enable_buttons()
	$"../..".update_status("STATUS: Idle", 0)
	
	
