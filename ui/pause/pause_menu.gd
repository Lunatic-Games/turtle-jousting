extends Popup


signal return_to_main_menu
signal return_to_lobby

var ignore_pause = false


func _ready():
	set_process_input(false)
	if get_tree().network_peer and !get_tree().is_network_server():
		$ButtonContainer/ReturnToLobbyButton.visible = false


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


func _on_SettingsButton_pressed():
	$SettingsMenu.popup()
	$ButtonContainer.visible = false


func _on_SettingsMenu_go_back():
	$ButtonContainer.visible = true
	$SettingsMenu.hide()


func _on_ReturnToLobbyButton_pressed():
	hide()
	set_process_input(false)
	emit_signal("return_to_lobby")


func _on_ReturnToMainMenuButton_pressed():
	hide()
	set_process_input(false)
	emit_signal("return_to_main_menu")
