extends Node2D

var level = 1

var move_blocks: int
var if_blocks: int

signal block_count_changed

func _ready():
	
	if level == 1:
		move_blocks = 1
		if_blocks = 1
		
	emit_signal("block_count_changed")
	
	$BeginLayer/beginUI.set_lvl(level)
	$BeginLayer.visible = true
		
