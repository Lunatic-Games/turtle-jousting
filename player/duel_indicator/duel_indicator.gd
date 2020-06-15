extends Popup


const CONTROL_BUTTONS = ["A", "B", "X", "Y"]
const KEYBOARD_BUTTONS = ["A", "W", "S", "D"]

var displayed_button
var player_1
var player_2
var duel_decided = false


func _ready():
	if get_tree().network_peer:
		rset_config("visible", MultiplayerAPI.RPC_MODE_REMOTE)


func _physics_process(delta):
	if get_tree().network_peer and is_network_master():
		rset("visible", visible)


# Check both players for presses
func _input(event):
	if event.get("pressed"):
		check_for_press(event, player_1, player_2)
		if !duel_decided:
			check_for_press(event, player_2, player_1)


# Set players and display the indicator
func display(p1, p2):
	player_1 = p1
	player_2 = p2
	
	var pos = p1.global_position
	pos += (p2.global_position - p1.global_position) / 2
	pos += Vector2(-18, -100)
	set_global_position(pos)
	random_button()
	popup()


# Check for correct button press
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


# Correct button pressed
func winning_press(winner, loser):
	winner.won_duel()
	loser.lost_duel((loser.global_position - winner.global_position).normalized())
	duel_decided = true
	queue_free()


# Change displayed button to be a new random one
func random_button():
	if displayed_button:
		get_node(displayed_button + "Button").visible = false
	displayed_button = CONTROL_BUTTONS[randi() % len(CONTROL_BUTTONS)]
	get_node(displayed_button + "Button").visible = true


# Neither player pressed the correct button, so both lose
func _on_Timer_timeout():
	if duel_decided:
		return
	var p1_gb = player_1.global_position
	var p2_gb = player_2.global_position
	player_1.lost_duel((p1_gb - p2_gb).normalized())
	player_2.lost_duel((p2_gb - p1_gb).normalized())
	queue_free()
