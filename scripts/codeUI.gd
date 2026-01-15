extends Control

@onready var block_container = $Panel/BlockBoundBox

func disable_buttons():
	$Panel/SpawnIfBlock.disabled = true
	$Panel/SpawnMoveBlock.disabled = true
	$Panel/Run.disabled = true
	
func enable_buttons():
	$Panel/SpawnIfBlock.disabled = false
	$Panel/SpawnMoveBlock.disabled = false
	$Panel/Run.disabled = false
