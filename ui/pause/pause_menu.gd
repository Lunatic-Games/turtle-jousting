extends Popup


signal return_to_main_menu
signal return_to_lobby


# Hide return to lobby if a non-host peer
func _ready():
	set_process_input(false)
	if get_tree().network_peer and !get_tree().is_network_server():
		$ButtonContainer/ReturnToLobbyButton.visible = false


# Handle resuming
func _input(event):
	if event.is_action("pause") and event.pressed:
		_on_ContinueButton_pressed()
		get_tree().set_input_as_handled()
	elif event.is_action("ui_cancel") and event.pressed:
		_on_ContinueButton_pressed()
		get_tree().set_input_as_handled()
		

# Hide self and stop capturing input
func _on_ContinueButton_pressed():
	hide()
	get_tree().paused = false
	set_process_input(false)


# Show settings
func _on_SettingsButton_pressed():
	$SettingsMenu.popup()
	$SettingsMenu/VBoxContainer/MasterContainer/Slider.grab_focus()
	$ButtonContainer.visible = false


# Make buttons visible again
func _on_SettingsMenu_popup_hide():
	$ButtonContainer.visible = true
	$ButtonContainer/ContinueButton.grab_focus()


# Tell game to return to lobby
func _on_ReturnToLobbyButton_pressed():
	hide()
	set_process_input(false)
	emit_signal("return_to_lobby")


# Tell game to return to main menu
func _on_ReturnToMainMenuButton_pressed():
	hide()
	set_process_input(false)
	emit_signal("return_to_main_menu")
