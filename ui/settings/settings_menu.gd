extends Popup


signal go_back


func _ready():
	pass


func _input(event):
	if event.is_action("ui_cancel") and event.pressed:
		_on_BackButton_pressed()

func _on_BackButton_pressed():
	emit_signal("go_back")


func _on_VibrationButton_pressed():
	var pressed = !$VBoxContainer/VibrationContainer/CheckBox.pressed
	$VBoxContainer/VibrationContainer/CheckBox.pressed = pressed


func _on_FullscreenButton_pressed():
	var pressed = !$VBoxContainer/FullscreenContainer/CheckBox.pressed
	$VBoxContainer/FullscreenContainer/CheckBox.pressed = pressed
	OS.window_fullscreen = pressed
