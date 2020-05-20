extends Control


var showing_credits = false


func _ready():
	$VisorTransition.lift_up()


func _input(event):
	if event.is_action("ui_cancel") and event.pressed and showing_credits:
		$Title.visible = true
		$ButtonContainer.visible = true
		$ButtonContainer/CreditsButton.grab_focus()
		showing_credits = false

func _on_PvpButton_pressed():
	$VisorTransition.bring_down()


func _on_HordeButton_pressed():
	print("Not implemented yet")


func _on_SettingsButton_pressed():
	$Title.visible = false
	$ButtonContainer.visible = false
	$SettingsMenu.show()
	$SettingsMenu/VBoxContainer/MusicContainer/Slider.grab_focus()


func _on_CreditsButton_pressed():
	$Title.visible = false
	$ButtonContainer.visible = false
	showing_credits = true


func _on_ExitButton_pressed():
	get_tree().quit()


func _on_SettingsMenu_go_back():
	$SettingsMenu.hide()
	$Title.visible = true
	$ButtonContainer.visible = true
	$ButtonContainer/SettingsButton.grab_focus()


func _on_VisorTransition_lifted_up():
	$ButtonContainer/PvpButton.grab_focus()


func _on_VisorTransition_brought_down():
	var _err = get_tree().change_scene("res://ui/lobby/lobby_menu.tscn")
