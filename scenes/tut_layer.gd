extends Panel

var grn = Color(0.106, 0.8, 0.0, 1.0)

func update_locks():
	print("LevelsDone: ", LevelState.levels_done)
	
	var buts = [$"1", $"2", $"3", $"4"]
	
	var r = LevelState.levels_done
	
	if r == 4:
		set_button_border_color(buts[3], grn)
		
	if r >= 4:
		r = 3
	
	for ii in range(r):
		set_button_border_color(buts[ii], grn)
		buts[ii+1].disabled = false
		
	
		
func set_button_border_color(btn: Button, color: Color) -> void:
	var style := btn.get_theme_stylebox("normal").duplicate()
	style.border_color = color
	btn.add_theme_stylebox_override("normal", style)
		
