extends ColorRect

var player
onready var DEFAULT_COLOR = color
const COLORS = [Color.red, Color.blue, Color.green, Color.yellow]

func _ready():
	pass
	
func _input(event):
	if !player or (get_tree().network_peer and !is_network_master()):
		return
	
	var dev_id = event.device
	if event is InputEventKey or event is InputEventMouse:
		dev_id = "keyboard"
	if typeof(dev_id) != typeof(player.device_id) or dev_id != player.device_id:
		return
		
	if event.is_action("ui_right") and event.pressed:
		player.color_i += 1
		if player.color_i >= len(COLORS):
			player.color_i = 0
		if get_tree().network_peer:
			rpc("update_data", player)
		else:
			update_data(player)
	
remotesync func update_data(player_data):
	player = player_data
	if player == null:
		color = DEFAULT_COLOR
	else:
		color = COLORS[player.color_i]
	if player == null or !player.number:
		$CenterContainer/Name.text = "Press A to join"
	else:
		$CenterContainer/Name.text = "Player " + str(player_data.number)
	if player == null or !player.net_id:
		set_network_master(1)
	else:
		set_network_master(player.net_id)
		
