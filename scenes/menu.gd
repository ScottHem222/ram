extends Node2D

var grn = Color(0.106, 0.8, 0.0, 1.0)

func _ready() -> void:
	$MainLayer.visible = true
	$TutLayer.visible = false
	$"TutLayer/1".disabled = false
	$TutLayer.update_locks()
	
	if LevelState.levels_done == 4:
		$MainLayer/Final.disabled = false
		set_button_border_color($MainLayer/Tutorials, grn)
		
	if LevelState.levels_done == 5:
		set_button_border_color($MainLayer/Final, grn)
		
		
func set_button_border_color(btn: Button, color: Color) -> void:
	var style := btn.get_theme_stylebox("normal").duplicate()
	style.border_color = color
	btn.add_theme_stylebox_override("normal", style)
