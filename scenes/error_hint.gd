extends Button

@onready var target_node = $"../../ErrorUI"  # adjust path

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	target_node.play_hint_msg()
