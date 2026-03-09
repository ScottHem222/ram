extends Panel

var grn = Color(0.106, 0.8, 0.0, 1.0)

func update_locks():
	print("LevelsDone: ", LevelState.levels_done)
	
	match LevelState.levels_done:
		1: 
			set_button_border_color($"1", grn)
			$"2".disabled = false
			
		2: 
			set_button_border_color($"1", grn)
			set_button_border_color($"2", grn)
			$"1".disabled = false
			$"2".disabled = false
			$"3".disabled = false
		3: 
			set_button_border_color($"1", grn)
			set_button_border_color($"2", grn)
			set_button_border_color($"3", grn)
			$"1".disabled = false
			$"2".disabled = false
			$"3".disabled = false
			$"4".disabled = false
		4: 
			set_button_border_color($"1", grn)
			set_button_border_color($"2", grn)
			set_button_border_color($"3", grn)
			set_button_border_color($"4", grn)
			$"1".disabled = false
			$"2".disabled = false
			$"3".disabled = false
			$"4".disabled = false
		5:
			set_button_border_color($"1", grn)
			set_button_border_color($"2", grn)
			set_button_border_color($"3", grn)
			set_button_border_color($"4", grn)
			$"1".disabled = false
			$"2".disabled = false
			$"3".disabled = false
			$"4".disabled = false
			
			
		
	
func set_button_border_color(btn: Button, color: Color) -> void:
	var style := btn.get_theme_stylebox("normal").duplicate()
	style.border_color = color
	btn.add_theme_stylebox_override("normal", style)
		
