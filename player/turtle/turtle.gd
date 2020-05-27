extends KinematicBody2D


export (bool) var locked = false
export (float) var locked_speed = 200
export (bool) var slowed = false
export (float) var slowed_speed = 50

const SPEED = 100
const MOVE_AXI_THRESHOLD = 0.1
const DEBUG = true

var device_id
var locked_direction = Vector2(0, 0)
var last_direction = Vector2(1, 0)
var joust_direction = Vector2(1, 0)


# Keeps track of movement input [button_active, joystick strength]
var movement_actions = {"up" : [false, 0], "right" : [false, 0],
	 "down" : [false, 0], "left" : [false, 0]}


func _ready():
	make_collisions_unique()
	$AnimationTree.active = true
	
	if get_tree().network_peer:
		rset_config("position", MultiplayerAPI.RPC_MODE_PUPPET)
		$Sprite.rset_config("flip_h", MultiplayerAPI.RPC_MODE_PUPPET)
		$Sprite.rset_config("offset", MultiplayerAPI.RPC_MODE_PUPPET)
		$CollisionPolygon2D.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		$Hitbox.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		
	if DEBUG:
		device_id = "keyboard"
	else:
		set_process_input(false)


func _input(event):
	if get_tree().network_peer and !is_network_master():
		return

	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"
	if typeof(device) != typeof(device_id) or device != device_id:
		return

	check_for_move_event(event, "up")
	check_for_move_event(event, "right")
	check_for_move_event(event, "down")
	check_for_move_event(event, "left")
	
	
func _physics_process(delta):
	if get_tree().network_peer and !is_network_master():
		return

	var movement
	if locked:
		movement = locked_direction.normalized() * locked_speed
	else:
		movement = get_input_movement()
	var _vel = move_and_slide(movement)
	update_sprite_direction(movement)
	
	if get_tree().network_peer:
		rset_unreliable("position", position)


func get_input_movement():
	var movement = Vector2()
	movement.y -= movement_actions["up"][1]
	movement.x += movement_actions["right"][1]
	movement.y += movement_actions["down"][1]
	movement.x -= movement_actions["left"][1]
	if movement_actions["up"][0]:
		movement.y -= 1
	if movement_actions["right"][0]:
		movement.x += 1
	if movement_actions["down"][0]:
		movement.y += 1
	if movement_actions["left"][0]:
		movement.x -= 1
	if movement.length() > 0.001:
		last_direction = movement.normalized()
	if movement.length() > 1:
		movement = movement.normalized()
	if slowed:
		movement *= slowed_speed
	else:
		movement *= SPEED
	return movement


func update_sprite_direction(movement):
	var idle = $AnimationTree.get("parameters/playback").get_current_node() == "idle"
	if ((idle and movement.x > 1) or 
			(locked and !locked_direction and joust_direction.x > 0.1)):
		set_direction(1)
	elif ((idle and movement.x < -1) or 
			(locked and !locked_direction and joust_direction.x < -0.1)):
		set_direction(-1)


func set_direction(dir_sign):
	$Sprite.flip_h = dir_sign != 1
	$Sprite.offset.x = -dir_sign * abs($Sprite.offset.x)
	$CollisionPolygon2D.scale.x = dir_sign * abs($CollisionPolygon2D.scale.x)
	$Hitbox.scale.x = dir_sign * abs($Hitbox.scale.x)
	if get_tree().network_peer and is_network_master():
		$Sprite.rset("flip_h", $Sprite.flip_h)
		$Sprite.rset("offset", $Sprite.offset)
		$CollisionPolygon2D.rset("scale", $CollisionPolygon2D.scale)
		$Hitbox.rset("scale", $Hitbox.scale)


func check_for_move_event(event, direction):
	if event.is_action("move_" + direction):
		if event is InputEventJoypadMotion:
			var strength = event.get_action_strength("move_" + direction)
			movement_actions[direction][1] = strength
		else: 
			movement_actions[direction][0] = event.is_pressed()


func invert_start_direction():
	set_direction(-1)
	last_direction.x *= -1

	
func make_collisions_unique():
	pass
	#$CollisionPolygon2D.polygon
	#$CollisionPolygon2D.polygon = $CollisionPolygon2D.polygon.duplicate()
	#var hitbox_col = $Hitbox/CollisionPolygon2D
	#hitbox_col.shape = hitbox_col.shape.duplicate()
	
	
func set_process_input(process):
	if process:
		.set_process_input(true)
	else:
		.set_process_input(false)
		movement_actions["up"] = [false, 0]
		movement_actions["right"] = [false, 0]
		movement_actions["down"] = [false, 0]
		movement_actions["left"] = [false, 0]
