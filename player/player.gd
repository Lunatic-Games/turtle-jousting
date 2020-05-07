extends KinematicBody2D

const SPEED = 200
const MOVE_AXI_THRESHOLD = 0.5

var device_id = 0

# Keeps track of movement input [button_active, joystick active]
var movement_actions = {"up" : [false, false], "right" : [false, false],
	 "down" : [false, false], "left" : [false, false]}

func _ready():
	if get_tree().network_peer:
		rset_config("position", MultiplayerAPI.RPC_MODE_REMOTE)

func _unhandled_input(event):
	if get_tree().network_peer and !is_network_master():
		return

	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"

	if typeof(device) != typeof(device_id):
		return			
	if device != device_id:
		return
	
	check_for_move_event(event, "up")
	check_for_move_event(event, "right")
	check_for_move_event(event, "down")
	check_for_move_event(event, "left")

func _physics_process(_delta):
	var movement = Vector2()
	if movement_actions["up"].has(true):
		movement.y -= 1
	if movement_actions["right"].has(true):
		movement.x += 1
	if movement_actions["down"].has(true):
		movement.y += 1
	if movement_actions["left"].has(true):
		movement.x -= 1
	var _vel = move_and_slide(movement.normalized() * SPEED)
	if get_tree().network_peer:
		rset("position", position)
	
func check_for_move_event(event, direction):
	if event.is_action("move_" + direction):
		if event is InputEventJoypadMotion:
			if direction == "right" or direction == "down":
				movement_actions[direction][1] = event.axis_value > 0.5
			else:
				movement_actions[direction][1] = event.axis_value < -0.5
		else: 
			movement_actions[direction][0] = event.is_pressed()
			
func load_data(data = {}):
	device_id = data.get("device_id", null)
	$ColorRect.color = data.get("color", Color(255, 255, 255))

