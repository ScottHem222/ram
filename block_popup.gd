extends LineEdit

@export var allowed_phrases: Array[String] = []

@export var popup_width: float = 400.0
@export var popup_max_height: float = 600.0
@export var popup_y_gap: float = 4.0

@onready var suggest: PopupMenu = $Suggest

var _last_valid = ""

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)
	suggest.id_pressed.connect(_on_suggest_pressed)

	_last_valid = ""

	suggest.min_size = Vector2(popup_width, 0)
	suggest.max_size = Vector2(popup_width, popup_max_height)
	suggest.add_theme_font_size_override("font_size", 24)
	suggest.unfocusable = true


func _input(event: InputEvent) -> void:
	if not has_focus():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var k = event as InputEventKey

		if k.keycode == KEY_TAB:
			if suggest.visible and suggest.item_count > 0:
				_accept_first_suggestion()
				get_viewport().set_input_as_handled()
				return

		if k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
			if suggest.visible and suggest.item_count > 0:
				_accept_first_suggestion()
				get_viewport().set_input_as_handled()
				return


func _accept_first_suggestion() -> void:
	text = suggest.get_item_text(0)
	caret_column = text.length()
	suggest.hide()
	release_focus()


func _on_text_changed(new_text: String) -> void:
	var q = new_text.strip_edges()

	suggest.clear()
	var matches: Array[String] = []

	for p in allowed_phrases:
		if p.begins_with(q) or q == "":
			matches.append(p)

	_last_valid = new_text

	if matches.size() > 0 and q != "":
		for i in range(matches.size()):
			suggest.add_item(matches[i], i)

		_show_suggestion_popup()
	else:
		suggest.hide()


func _show_suggestion_popup() -> void:
	var screen_pos = global_position + Vector2(0, size.y + popup_y_gap)
	var width = maxf(size.x, popup_width)

	suggest.min_size = Vector2(width, 0)
	suggest.max_size = Vector2(width, popup_max_height)

	var rect = Rect2(screen_pos, Vector2(width, popup_max_height))
	suggest.popup(rect)

	call_deferred("grab_focus")


func _on_suggest_pressed(id: int) -> void:
	text = suggest.get_item_text(id)
	caret_column = text.length()
	suggest.hide()
	release_focus()


func _on_text_submitted(submitted: String) -> void:
	var s = submitted.strip_edges()

	if allowed_phrases.has(s):
		release_focus()
	else:
		text = ""
