extends Control


var showing_credits = false


# Begin visor animation
func _ready():
	$VisorTransition.lift_up()


# Check for cancel while showing credits
func _input(event):
	if event.is_action("ui_cancel") and event.pressed and showing_credits:
		$Title.visible = true
		$ButtonContainer.visible = true
		$ButtonContainer/CreditsButton.grab_focus()
		showing_credits = false


# Begin transition to lobby
func _on_PvpButton_pressed():
	$VisorTransition.bring_down(self, "_go_to_lobby")


# Will eventually lead to Horde lobby
func _on_HordeButton_pressed():
	print("Not implemented yet")


# Go to settings
func _on_SettingsButton_pressed():
	$Title.visible = false
	$ButtonContainer.visible = false
	$SettingsMenu.popup()
	$SettingsMenu/VBoxContainer/MusicContainer/Slider.grab_focus()


# Hide UI to show credits
func _on_CreditsButton_pressed():
	$Title.visible = false
	$ButtonContainer.visible = false
	showing_credits = true


# Exit game
func _on_ExitButton_pressed():
	get_tree().quit()


# Show UI again
func _on_SettingsMenu_popup_hide():
	$Title.visible = true
	$ButtonContainer.visible = true
	$ButtonContainer/SettingsButton.grab_focus()


# Grab focus
func _on_VisorTransition_lifted_up():
	$ButtonContainer/PvpButton.grab_focus()


# Change scene to lobby
func _go_to_lobby():
	var _err = get_tree().change_scene("res://ui/lobby/lobby_menu.tscn")
