extends Camera2D

@export var speed := 300.0   # pixels per second


func _ready():
	make_current()

func _process(delta):
	var move := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1

	position += move * speed * delta
