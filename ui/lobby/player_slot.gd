extends ColorRect

var device_id
var color_i = 0
const COLORS = [Color.red, Color.blue, Color.green, Color.yellow]

func _ready():
	color = COLORS[color_i]
	
func _input(event):
	if event is InputEventMouse:
		return
		
	if get_tree().network_peer and !is_network_master():
		print(get_network_master())
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
		
func reset():
	$CenterContainer/Name.text = "Press A to join"
	#device_id = null
	
func player_loaded(number, dev_id = null):
	device_id = dev_id
	$CenterContainer/Name.text = "Player " + str(number)
