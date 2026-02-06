extends Control

@onready var block_container = $Panel/BlockBoundBox
@onready var tour_1 = $CanvasLayer/Tour1
@onready var tour_2 = $CanvasLayer/Tour2

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
		$Panel/SpawnIfBlock.visible = false
		$Panel/SpawnTurnBlock.visible = false
		
		$Panel/SpawnWhileBlock.visible = false
		$Panel/SpawnMoveBlock.visible = false
		
		$Panel/SpawnAMoveBlock.visible = true
		$Panel/SpawnForBlock.visible = true	
		
	
func _ready() -> void:
	tour_1.visible = false
	tour_2.visible = false
	
func show_tour() -> void:
	tour_1.visible = true
		
