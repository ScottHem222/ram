extends Node2D

func move_by(dx: float):
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position:x", position.x + dx, 0.5)
