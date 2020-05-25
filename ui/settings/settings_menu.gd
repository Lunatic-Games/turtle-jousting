extends Popup


# Check for cancel
func _input(event):
	if visible and event.is_action("ui_cancel") and event.pressed:
		_on_BackButton_pressed()


# Hide self, other menus should connect to signal emitted on hide
func _on_BackButton_pressed():
	hide()


# Toggle vibration
func _on_VibrationButton_pressed():
	var pressed = !$VBoxContainer/VibrationContainer/CheckBox.pressed
	$VBoxContainer/VibrationContainer/CheckBox.pressed = pressed


# Toggle fullscreen
func _on_FullscreenButton_pressed():
	var pressed = !$VBoxContainer/FullscreenContainer/CheckBox.pressed
	$VBoxContainer/FullscreenContainer/CheckBox.pressed = pressed
	OS.window_fullscreen = pressed
