extends Popup


var ignore_pause = false


func _ready():
	set_process_input(false)


func _input(event):
	if event.is_action("pause") and event.pressed:
		_on_ContinueButton_pressed()
		get_tree().set_input_as_handled()
	elif event.is_action("ui_cancel") and event.pressed:
		_on_ContinueButton_pressed()
		get_tree().set_input_as_handled()
		

func _on_ContinueButton_pressed():
	hide()
	get_tree().paused = false
	set_process_input(false)
