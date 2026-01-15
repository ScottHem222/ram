extends Button

@onready var target_node = $"../../beginUI"  # adjust path

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	target_node.queue_free()
