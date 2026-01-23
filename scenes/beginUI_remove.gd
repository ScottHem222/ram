extends Button

@onready var target_node = $"../../beginUI"  # adjust path
@onready var level_ui := get_node("../../../GameUILayer/level_UI")

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if LevelState.curr_lvl == 1:
		level_ui.show_tour()
	target_node.queue_free()
