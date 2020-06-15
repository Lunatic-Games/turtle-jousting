extends Control


const NAMES = ["Joe Zlonicky", "Matthias Harden", "Noah Jacobsen",
	"Davis Carlson"]
const COLORS = [Color("bf5c00"), Color("771cff"), Color("299e57"),
	Color("ac4141")]
var showing_credits = false


# Begin visor animation
func _ready():
	$VisorTransition.lift_up()
	$AnimationPlayer.play("fade_music_in")
	var i = 0
	for player in get_tree().get_nodes_in_group("player"):
		player.knight.get_node("Name").text = NAMES[i]
		player.set_color(COLORS[i])
		i += 1


# Check for cancel while showing credits
func _input(event):
	if event.is_action("ui_cancel") and event.pressed and showing_credits:
		set_player_name_visibility(false)
		$Title.visible = true
		$ButtonContainer.visible = true
		$ButtonContainer/CreditsButton.grab_focus()
		showing_credits = false


# Begin transition to lobby
func _on_PvpButton_pressed():
	$VisorTransition.bring_down(self, "_go_to_lobby")
	$AnimationPlayer.play("fade_music_out")


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
	set_player_name_visibility(true)
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


# Set whether to show player names and hide health bars
func set_player_name_visibility(visibility):
	for knight in get_tree().get_nodes_in_group("knight"):
		knight.get_node("HealthBar").visible = !visibility
		knight.get_node("Name").visible = visibility
