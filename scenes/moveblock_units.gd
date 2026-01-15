extends LineEdit

const MIN_VAL := 1
const MAX_VAL := 100

func _ready():
	text_changed.connect(_on_text_changed)
	focus_exited.connect(_on_focus_exited)

func _on_text_changed(new_text: String) -> void:
	# Remove anything that is not a digit
	var filtered := ""
	for c in new_text:
		if c.is_valid_int():
			filtered += c

	if filtered != new_text:
		text = filtered
		caret_column = text.length()

func _on_focus_exited() -> void:
	if text == "":
		text = str(MIN_VAL)
		return

	var value := int(text)
	value = clamp(value, MIN_VAL, MAX_VAL)
	text = str(value)
