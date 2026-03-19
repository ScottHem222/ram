extends Node

var curr_lvl: int = 1
var levels_done: int = 0


## Lvl specifics

var lvl4_gold: int = 12
var lvl5_energy: int = 250
var lvl5_score:int = 0

var lvl5_scoreboard: Array = []


func _ready() -> void:
	curr_lvl = 0
	levels_done = 3
