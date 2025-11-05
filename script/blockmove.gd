extends Control

@onready var distance_field = $PanelContainer/HBoxContainer/DistanceField
@onready var autocomplete_menu = $AutocompleteMenu

var autocomplete_items = ["10", "20", "robot.speed", "sensor.range", "cargo_weight"]

func _ready():
	distance_field.text_changed.connect(_on_text_changed)
	autocomplete_menu.id_pressed.connect(_on_autocomplete_selected)

func _on_text_changed(new_text: String):
	autocomplete_menu.clear()
	if new_text == "":
		autocomplete_menu.hide()
		return

	for item in autocomplete_items:
		if item.begins_with(new_text):
			autocomplete_menu.add_item(item)

	if autocomplete_menu.item_count > 0:
		var rect = distance_field.get_global_rect()
		autocomplete_menu.position = Vector2(rect.position.x, rect.position.y + rect.size.y)
		autocomplete_menu.show()
	else:
		autocomplete_menu.hide()

func _on_autocomplete_selected(id):
	distance_field.text = autocomplete_menu.get_item_text(id)
	autocomplete_menu.hide()

func to_dict() -> Dictionary:
	return {
		"type": "move",
		"params": { "distance": distance_field.text }
	}
