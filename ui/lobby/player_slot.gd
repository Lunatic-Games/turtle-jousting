extends ColorRect

onready var DEFAULT_COLOR = color
const COLORS = [Color.red, Color.blue, Color.green, Color.yellow]

var device_id
var color_i = -1

func _ready():
	pass


func _process(_delta):
	if !get_tree().network_peer or !is_network_master():
		return
	rpc_unreliable("update_color", color_i)


func _input(event):
	if get_tree().network_peer and !is_network_master():
		return
	
	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"
		if typeof(device_id) == TYPE_INT:
			return

	if device != device_id:
		if color != DEFAULT_COLOR:
			print("Wrong device")
		return
		
	if event.is_action("ui_right") and event.pressed:
		color_i += 1
		if color_i >= len(COLORS):
			color_i = 0
		color = COLORS[color_i]


func load_player(number, player_data={}):
	set_process(true)
	$CenterContainer/Name.text = "Player " + str(number)
	color_i = player_data.get("color_i", 0)
	color = COLORS[color_i]
	device_id = player_data.get("device_id", 0)
	

func reset():
	set_process(false)
	$CenterContainer/Name.text = "Press A to join"
	color_i = -1
	color = DEFAULT_COLOR
	device_id = null
	
func get_player_data():
	return { "device_id" : device_id, "color_i" : color_i, "color" : color}

remote func update_color(i):
	if get_tree().get_rpc_sender_id() == get_tree().get_network_unique_id():
		return
	color_i = i
	if i == -1:
		color = DEFAULT_COLOR
	else:
		color = COLORS[color_i]

