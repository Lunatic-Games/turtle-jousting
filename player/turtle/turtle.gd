extends KinematicBody2D


signal movement_actions_changed

export (bool) var locked = false
export (float) var locked_speed = 200
export (bool) var slowed = false
export (float) var slowed_speed = 50

const SPEED = 100
const MOVE_THRESHOLD = 0.45
const DEBUG = false

var speed_modifier = 1
var device_id
var locked_direction = Vector2(0, 0)
var last_direction = Vector2(1, 0)

# Keeps track of movement input [button_active, joystick strength]
var movement_actions = {"up" : [false, 0], "right" : [false, 0],
	 "down" : [false, 0], "left" : [false, 0]}


# Setup and setting property network permissions
func _ready():
	$AnimationTree.active = true
	if DEBUG:
		device_id = 0
	else:
		set_process_input(false)
	
	if get_tree().network_peer:
		rset_config("position", MultiplayerAPI.RPC_MODE_PUPPET)
		$Reversable.rset_config("scale", MultiplayerAPI.RPC_MODE_REMOTE)
		$CollisionPolygon2D.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		$Hitbox.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)


# Handle inputs for device with corresponding id
func _input(event):
	if !_should_handle_event(event):
		return
	check_for_move_event(event, "up")
	check_for_move_event(event, "right")
	check_for_move_event(event, "down")
	check_for_move_event(event, "left")


# Determine if event is relavent to this turtle
func _should_handle_event(event):
	if DEBUG:
		return true
	
	if get_tree().network_peer and !is_network_master():
		return false

	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"
	if typeof(device) != typeof(device_id) or device != device_id:
		return false
	
	return true


# Update movement
func _physics_process(_delta):
	if !_should_process():
		return

	var movement
	if locked:
		movement = locked_direction.normalized() * locked_speed
	else:
		movement = get_input_movement()
		if slowed:
			movement *= slowed_speed
		else:
			movement *= SPEED * speed_modifier
		moved(movement)
	var _vel = move_and_slide(movement)
	update_sprite_direction(movement)
	
	if get_tree().network_peer:
		rset_unreliable("position", position)


# Should only process if offline or network master
func _should_process():
	return !get_tree().network_peer or is_network_master()


# Determine movement based on inputs
func get_input_movement():
	var movement = Vector2()
	movement.y -= movement_actions["up"][1] + int(movement_actions["up"][0])
	movement.x += movement_actions["right"][1] + int(movement_actions["right"][0])
	movement.y += movement_actions["down"][1] + int(movement_actions["down"][0])
	movement.x -= movement_actions["left"][1] + int(movement_actions["left"][0])
	if movement.length() < MOVE_THRESHOLD:
		return Vector2(0, 0)
	if movement:
		last_direction = movement.normalized()
	if movement.length() > 1:
		movement = movement.normalized()
	return movement


# Decide what direction to face
func update_sprite_direction(movement):
	if movement.x > 1:
		set_direction(1)
	elif movement.x < -1:
		set_direction(-1)


# Set the facing direction of sprite and components
func set_direction(dir_sign):
	$Reversable.scale.x = dir_sign * abs($Reversable.scale.x)
	$CollisionPolygon2D.scale.x = dir_sign * abs($CollisionPolygon2D.scale.x)
	$Hitbox.scale.x = dir_sign * abs($Hitbox.scale.x)
	if get_tree().network_peer and is_network_master():
		$Reversable.rset("scale", $Reversable.scale)
		$CollisionPolygon2D.rset("scale", $CollisionPolygon2D.scale)
		$Hitbox.rset("scale", $Hitbox.scale)


# Check for move event and update movement_actions
func check_for_move_event(event, direction):
	if event.is_action("move_" + direction):
		if event is InputEventJoypadMotion:
			var strength = event.get_action_strength("move_" + direction)
			movement_actions[direction][1] = strength
			emit_signal("movement_actions_changed", direction, 1, strength)
		else:
			movement_actions[direction][0] = event.is_pressed()
			emit_signal("movement_actions_changed", direction, 0, event.is_pressed())
		


# Start facing the opposite direction
func invert_start_direction():
	set_direction(-1)
	last_direction.x *= -1
	

# Set whether to process input, reset current inputs when process set to false
func set_process_input(process):
	if process:
		.set_process_input(true)
	else:
		.set_process_input(false)
		reset_movement_presses()
		

# Clears saved states of buttons and joystick direction
func reset_movement_presses():
	movement_actions["up"] = [false, 0]
	movement_actions["right"] = [false, 0]
	movement_actions["down"] = [false, 0]
	movement_actions["left"] = [false, 0]


# Checks for running into another turtle or a knight
func _on_Hitbox_area_entered(area):
	if area.is_in_group("turtle_hitbox"):
		hit_turtle(area)
	elif area.is_in_group("knight") and !is_a_parent_of(area):
		hit_knight(area)
	elif area.is_in_group("powerup") and has_node("Knight"):
		area.pick_up(self)


# Hit another turtle
func hit_turtle(_turtle):
	pass


# Hit another turtle's knight
func hit_knight(_knight):
	pass


# Will be extended by player
func moved(_movement):
	pass
