extends ColorRect

onready var DEFAULT_COLOR = color
const COLORS = [Color.red, Color.blue, Color.green, Color.yellow]

var device_id
var color_i = 0

func _ready():
	pass


func _process(_delta):
	if !get_tree().network_peer:
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
		return
		
	if event.is_action("ui_right") and event.pressed:
		color_i += 1
		if color_i >= len(COLORS):
			color_i = 0


func load_player(number, device=null):
	$CenterContainer/Name.text = "Player " + str(number)
	color_i = 0
	color = COLORS[color_i]
	device_id = device
	
func update_color(i):
	color_i = i
	color = COLORS[color_i]

	
