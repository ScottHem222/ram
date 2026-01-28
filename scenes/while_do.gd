extends LineEdit

@export var allowed_phrases: Array[String] = [
	"Turn()",
	"turn()",
	"move()",
	"Move()"
]

@onready var suggest: PopupMenu = $Suggest

var _last_valid := ""

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	suggest.id_pressed.connect(_on_suggest_pressed)

	_last_valid = ""


func _on_text_changed(new_text: String) -> void:
	var q := new_text.strip_edges()

	# Build matching suggestions
	suggest.clear()
	var matches: Array[String] = []
	for p in allowed_phrases:
		if p.begins_with(q) or q == "":
			matches.append(p)

	# If what they typed is not a prefix of ANY allowed phrase, revert
	var is_prefix_of_any := false
	for p in allowed_phrases:
		if p.begins_with(q) or q == "":
			is_prefix_of_any = true
			break

	if not is_prefix_of_any:
		text = _last_valid
		caret_column = text.length()
		return
	else:
		_last_valid = new_text

	# Show suggestions
	if matches.size() > 0 and q != "":
		for i in range(matches.size()):
			suggest.add_item(matches[i], i)

		# position popup under the LineEdit
		var r := Rect2(Vector2(0, size.y), Vector2(size.x, 200))
		suggest.popup(r)
	else:
		suggest.hide()


func _on_suggest_pressed(id: int) -> void:
	text = suggest.get_item_text(id)
	caret_column = text.length()
	suggest.hide()


func _on_text_submitted(submitted: String) -> void:
	var s := submitted.strip_edges()

	# Only accept exact allowed phrases on Enter
	if allowed_phrases.has(s):
		# valid command
		release_focus()
	else:
		# reject
		text = ""
