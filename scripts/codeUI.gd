extends Control

@onready var block_container = $Panel/BlockBoundBox
@onready var tour_1 = $CanvasLayer/Tour1
@onready var tour_2 = $CanvasLayer/Tour2

func disable_buttons():
	$Panel/SpawnIfBlock.disabled = true
	$Panel/SpawnMoveBlock.disabled = true
	$Panel/Run.disabled = true
	
func enable_buttons():
	$Panel/SpawnIfBlock.disabled = false
	$Panel/SpawnMoveBlock.disabled = false
	$Panel/Run.disabled = false


func update_status(new, col):
	$Panel/Status.text = new
	var new_col = null
	if col == 0:
		new_col = Color(1.0, 0.8, 0.0, 1.0)
	else:
		new_col = Color(0.106, 0.8, 0.0, 1.0)
		
	$Panel/Status.set("theme_override_colors/font_color",new_col)
	
func _ready() -> void:
	tour_1.visible = false
	tour_2.visible = false
	
func show_tour() -> void:
	tour_1.visible = true
		
