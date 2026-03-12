extends Button

@onready var target_node = $"../../ErrorUI"  

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	# reset mined tiles
	if LevelState.curr_lvl == 4:
		get_tree().get_first_node_in_group("level_4_root").restore_tilemap_to_original()
		
	target_node.queue_free()
