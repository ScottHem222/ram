extends Control

@onready var block_container = $Panel/BlockBoundBox
@onready var tour_1 = $CanvasLayer/Tour1
@onready var tour_2 = $CanvasLayer/Tour2
@onready var tour_3 = $CanvasLayer/Tour3

signal rtm_ui
signal reset_lvl

func disable_buttons():
	$Panel/SpawnIfBlock.disabled = true
	$Panel/SpawnMoveBlock.disabled = true
	$Panel/SpawnTurnBlock.disabled = true
	$Panel/SpawnWhileBlock.disabled = true
	$Panel/SpawnAMoveBlock.disabled = true
	$Panel/SpawnForBlock.disabled = true
	$Panel/Run.disabled = true
	
func enable_buttons():
	$Panel/SpawnIfBlock.disabled = false
	$Panel/SpawnMoveBlock.disabled = false
	$Panel/SpawnTurnBlock.disabled = false
	$Panel/SpawnWhileBlock.disabled = false
	$Panel/SpawnAMoveBlock.disabled = false
	$Panel/SpawnForBlock.disabled = false
	$Panel/Run.disabled = false


func update_status(new, col):
	$Panel/Status.text = new
	var new_col = null
	if col == 0:
		new_col = Color(1.0, 0.8, 0.0, 1.0)
	else:
		new_col = Color(0.106, 0.8, 0.0, 1.0)
		
	$Panel/Status.set("theme_override_colors/font_color",new_col)
	
func update_goal_msg():
	
	if LevelState.curr_lvl == 5:
		var nrg
		if LevelState.lvl5_energy <= 0:
			nrg = 0
		else:
			nrg = LevelState.lvl5_energy
		
		$goal.text = str("Energy: ", nrg, "\nScore: ", LevelState.lvl5_score)
	
	if LevelState.curr_lvl < 4:
		$goal.text = "Current Goal:\nReach Ore Deposit"
	elif LevelState.curr_lvl == 4:
		$goal.text = "Current Goal:\nMine the correct Ore"
	
	
	
	
	
func setup_block_buttons():
	if LevelState.curr_lvl == 1:
		$Panel/SpawnIfBlock.visible = false
		$Panel/SpawnTurnBlock.visible = true
		
		$Panel/SpawnWhileBlock.visible = false
		$Panel/SpawnMoveBlock.visible = true
		
		$Panel/SpawnAMoveBlock.visible = false
		$Panel/SpawnForBlock.visible = false
	elif LevelState.curr_lvl == 2:
		$Panel/SpawnIfBlock.visible = true
		$Panel/SpawnTurnBlock.visible = false
		
		$Panel/SpawnWhileBlock.visible = false
		$Panel/SpawnMoveBlock.visible = true
		
		$Panel/SpawnAMoveBlock.visible = false
		$Panel/SpawnForBlock.visible = false
	elif LevelState.curr_lvl == 3:
		$Panel/SpawnIfBlock.visible = true
		$Panel/SpawnTurnBlock.visible = false
		
		$Panel/SpawnWhileBlock.visible = true
		$Panel/SpawnMoveBlock.visible = false
		
		$Panel/SpawnAMoveBlock.visible = false
		$Panel/SpawnForBlock.visible = false
	elif LevelState.curr_lvl == 4:
		$Panel/SpawnIfBlock.visible = true
		$Panel/SpawnTurnBlock.visible = false
		
		$Panel/SpawnWhileBlock.visible = false
		$Panel/SpawnMoveBlock.visible = false
		
		$Panel/SpawnAMoveBlock.visible = true
		$Panel/SpawnForBlock.visible = true	
	elif LevelState.curr_lvl == 5:
		$Panel/SpawnIfBlock.visible = true
		$Panel/SpawnTurnBlock.visible = false
		
		$Panel/SpawnWhileBlock.visible = false
		$Panel/SpawnMoveBlock.visible = false
		
		$Panel/SpawnAMoveBlock.visible = true
		$Panel/SpawnForBlock.visible = true	
		
		
	
func _ready() -> void:
	tour_1.visible = false
	tour_2.visible = false
	tour_3.visible = false
	update_goal_msg()
	$menu.pressed.connect(menu_pressed)
	$reset.pressed.connect(rst_pressed)
	
func show_tour() -> void:
	tour_1.visible = true
	
func show_tour_l2() -> void:
	tour_3.visible = true
	
func menu_pressed() -> void:
	rtm_ui.emit()
	
func rst_pressed() -> void:
	reset_lvl.emit()
	enable_buttons()
	update_status("STATUS: Idle", 0)
	
	if LevelState.curr_lvl == 4:
		get_tree().get_first_node_in_group("level_4_root").restore_tilemap_to_original()
		
	if LevelState.curr_lvl == 5:
		LevelState.lvl5_energy = 250
		LevelState.lvl5_score = 0
		
