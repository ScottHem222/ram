extends CharacterBody2D

@export var speed := 200.0
@export var turn_degrees := 90.0   # how much to rotate when blocked

@onready var ray := $ray_fw
var move := true

var direction := Vector2.RIGHT


func _physics_process(delta):
	# If we hit a wall, rotate left or right randomly
	if move:
		if ray.is_colliding():
			if randi() % 2 == 0:
				direction = direction.rotated(deg_to_rad(turn_degrees))
			else:
				direction = direction.rotated(-deg_to_rad(turn_degrees))


		velocity = direction.normalized() * speed
		move_and_slide()

		# Rotate visual to match direction
		rotation = direction.angle()
