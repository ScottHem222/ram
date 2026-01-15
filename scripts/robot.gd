extends CharacterBody2D

@export var speed := 200.0
@export var turn_degrees := 90.0

@onready var ray := $ray_fw

var auto_move := false
var turn := false
var mineGold := false
var direction := Vector2.RIGHT


func _physics_process(delta):
	if auto_move:
		if turn and ray.is_colliding():
			if randi() % 2 == 0:
				direction = direction.rotated(deg_to_rad(turn_degrees))
			else:
				direction = direction.rotated(-deg_to_rad(turn_degrees))

		velocity = direction.normalized() * speed
		move_and_slide()
		rotation = direction.angle()


# Call this when auto_move is false
func move_step(distance: float) -> void:
	if auto_move:
		return

	var motion = direction.normalized() * distance
	global_position += motion
	rotation = direction.angle()
