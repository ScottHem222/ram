extends Control

@onready var block_container = $BlockContainer
@onready var robot = $Robot

func _ready():
	$RunButton.pressed.connect(_on_run_pressed)

func _on_run_pressed():
	for child in block_container.get_children():
		if child.has_method("to_dict"):
			run_block(child.to_dict())

func run_block(block_data: Dictionary):
	match block_data["type"]:
		"move":
			var distance = float(block_data["params"]["distance"])
			robot.move_by(distance)
