extends ColorRect

var device_id
var color_i = 0
onready var DEFAULT_COLOR = color
const COLORS = [Color.red, Color.blue, Color.green, Color.yellow]

func _ready():
	rset_config("color", MultiplayerAPI.RPC_MODE_REMOTE)
	
func _input(event):
	if get_tree().network_peer and !is_network_master():
		return
	
	var dev_id = event.device
	if event is InputEventKey or event is InputEventMouse:
		dev_id = "keyboard"
	if typeof(dev_id) != typeof(device_id) or dev_id != device_id:
		return
		
	if event.is_action("ui_right") and event.pressed:
		color_i += 1
		if color_i >= len(COLORS):
			color_i = 0
		color = COLORS[color_i]
		if get_tree().network_peer:
			rset("color", color)
		
remote func update_color(c):
	color = c
	
func reset():
	$CenterContainer/Name.text = "Press A to join"
	color_i = 0
	color = DEFAULT_COLOR
	#device_id = null
	
func player_loaded(number, dev_id = null):
	if dev_id != null:
		device_id = dev_id
	color_i = 0
	color = COLORS[color_i]
	$CenterContainer/Name.text = "Player " + str(number)
