extends Popup


var line_edit


const BASE_36_DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']


func display(edit):
	$Panel/Buttons/B0.grab_focus()
	line_edit = edit
	$TextPanel/Label.text = edit.text
	popup()
	
func _input(event):
	if !visible:
		return
	if event.is_action("ui_cancel") and event.pressed:
		if len(line_edit.text) == 0:
			_on_EnterButton_pressed()
			return
		var cursor_pos = max(0, line_edit.caret_position - 1)
		line_edit.text = line_edit.text.substr(0, len(line_edit.text) - 1)
		line_edit.caret_position = cursor_pos
		$TextPanel/Label.text = line_edit.text
	if event.is_action("ui_start") and event.pressed:
		_on_EnterButton_pressed()

func _ready():
	var i = 0
	for button in get_tree().get_nodes_in_group("keyboard_button"):
		button.text = BASE_36_DIGITS[i]
		button.connect("pressed", self, "button_pressed", [BASE_36_DIGITS[i]])
		i += 1
		
func button_pressed(c):
	line_edit.append_at_cursor(c)
	$TextPanel/Label.text = line_edit.text


func _on_EnterButton_pressed():
	hide()
	line_edit.grab_focus()


func _on_ClearButton_pressed():
	line_edit.text = ""
	$TextPanel/Label.text = ""
