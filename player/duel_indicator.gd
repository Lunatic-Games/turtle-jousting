extends ColorRect


signal decided

const CONTROL_BUTTONS = ["A", "B", "X", "Y"]
const KEYBOARD_BUTTONS = ["A", "W", "S", "D"]

var displayed_button
var player_1
var player_2

func _input(event):
	if event.get("pressed"):
		check_for_press(event, player_1, player_2)
		check_for_press(event, player_2, player_1)


func check_for_press(event, player, other_player):
	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"

	if typeof(device) != typeof(player.device_id):
		return
	if device != player.device_id:
		return
	
	if event.is_action("duel_a") and displayed_button == "A":
		winning_press(player, other_player)
	elif event.is_action("duel_b") and displayed_button == "B":
		winning_press(player, other_player)
	elif event.is_action("duel_x") and displayed_button == "X":
		winning_press(player, other_player)
	elif event.is_action("duel_y") and displayed_button == "Y":
		winning_press(player, other_player)


func winning_press(winner, loser):
	winner.won_duel()
	loser.lost_duel((loser.global_position - winner.global_position).normalized())
	emit_signal("decided", self)


func random_button(p1, p2):
	player_1 = p1
	player_2 = p2
	displayed_button = CONTROL_BUTTONS[randi() % len(CONTROL_BUTTONS)]
	$Label.text = displayed_button


func _on_Timer_timeout():
	var p1_gb = player_1.global_position
	var p2_gb = player_2.global_position
	player_1.lost_duel((p1_gb - p2_gb).normalized())
	player_2.lost_duel((p2_gb - p1_gb).normalized())
	emit_signal("decided", self)
