extends Panel

func update_locks():
	print("LevelsDone: ", LevelState.levels_done)
	
	var buts = [$"1", $"2", $"3", $"4"]
	
	for ii in range(LevelState.levels_done):
		buts[ii+1].disabled = false
		
