extends Node2D

func _ready() -> void:
	$MainLayer.visible = true
	$TutLayer.visible = false
	$"TutLayer/1".disabled = false
	$TutLayer.update_locks()
