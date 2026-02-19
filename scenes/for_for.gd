extends LineEdit

@export var allowed_phrases: Array[String] = [
	"gold",
	"Gold"
]

@onready var suggest: PopupMenu = $Suggest
var _last_valid := ""


func _ready() -> void:
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	suggest.id_pressed.connect(_on_suggest_pressed)
	_last_valid = ""


# --------------------------------------------------
# TEXT CHANGE
# --------------------------------------------------
func _on_text_changed(new_text: String) -> void:
	var q := new_text.strip_edges()

	suggest.clear()
	var matches: Array[String] = []

	for p in allowed_phrases:
		if p.begins_with(q) or q == "":
			matches.append(p)

	var is_prefix := false
	for p in allowed_phrases:
		if p.begins_with(q) or q == "":
			is_prefix = true
			break

	if not is_prefix:
		text = _last_valid
		caret_column = text.length()
		return
	else:
		_last_valid = new_text

	if matches.size() > 0 and q != "":
		for i in matches.size():
			suggest.add_item(matches[i], i)

		var r := Rect2(Vector2(0, size.y), Vector2(size.x, 200))
		suggest.popup(r)
	else:
		suggest.hide()


# --------------------------------------------------
# SUGGEST CLICK
# --------------------------------------------------
func _on_suggest_pressed(_id: int) -> void:
	_accept_first()


# --------------------------------------------------
# ENTER SUBMIT
# --------------------------------------------------
func _on_text_submitted(submitted: String) -> void:
	var s := submitted.strip_edges()

	if allowed_phrases.has(s):
		release_focus()
	else:
		text = ""


# --------------------------------------------------
#input
# --------------------------------------------------
func _shortcut_input(event: InputEvent) -> void:
	if not has_focus():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey

		if key.keycode == KEY_TAB:
			if suggest.visible and suggest.item_count > 0:
				_accept_first()
				accept_event()

		elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
			if suggest.visible and suggest.item_count > 0:
				_accept_first()
				accept_event()


# --------------------------------------------------
# ACCEPT FIRST SUGGESTION
# --------------------------------------------------
func _accept_first() -> void:
	if suggest.item_count == 0:
		return

	text = suggest.get_item_text(0)
	caret_column = text.length()
	suggest.hide()
