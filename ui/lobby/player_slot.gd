extends ColorRect

var player
onready var DEFAULT_COLOR = color
onready var Player = preload("res://ui/lobby/player_data.gd")
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
			rpc("update_data_js", to_json(player.to_dict))
		else:
			update_data(player)
	
remotesync func update_data_js(player_data_js):
	var player_data = parse_json(player_data_js)
	var player = Player.new()
	player.from_dict(player_data)
	update_data(player)

func update_data(player_data):
	var player = Player.new()
	player.from_dict(parse_json(player_data))
	if player == null or !player.color_i:
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
		
