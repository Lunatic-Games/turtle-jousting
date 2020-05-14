extends KinematicBody2D

export (bool) var idle = true
export (bool) var charging_joust = false
export (bool) var joust_attacking = false
export (bool) var parrying = false
export (bool) var locked = false
export (float) var locked_speed = 200
export (bool) var slowed = false
export (float) var slowed_speed = 100


const SPEED = 200
const MOVE_AXI_THRESHOLD = 0.1
const JOUST_AXI_THRESHOLD = 0.5
const MOUSE_SENSITIVITY = 0.01
const JOUST_INDICATOR_RADIUS = 250
const MAX_JOUST_CHARGE = 300
const JOUST_CHARGE_RATE = 200
const JOUST_CHARGE_DIST_MODIFIER = 1.5
const DEBUG = true

var device_id = null
var locked_direction = Vector2(0, 0)
var last_direction = Vector2(1, 0)
var joy_direction = Vector2(1, 0)
var joust_indicator_charge = 0.0
var joust_charge = 0.0

# Keeps track of movement input [button_active, joystick strength]
var movement_actions = {"up" : [false, 0], "right" : [false, 0],
	 "down" : [false, 0], "left" : [false, 0]}

func _ready():
	make_collisions_unique()
	if get_tree().network_peer:
		rset_config("position", MultiplayerAPI.RPC_MODE_PUPPET)
		$Sprite.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		$LanceHitbox.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		$KnightHitbox.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		$TurtleHitbox.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
	if DEBUG:
		device_id = 0


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
	
	if event is InputEventMouseMotion:
		joy_direction += event.relative * MOUSE_SENSITIVITY
		joy_direction = joy_direction.clamped(1)
	elif event is InputEventJoypadMotion:
		var horiz = Input.get_joy_axis(device_id, JOY_AXIS_0)
		var vert = Input.get_joy_axis(device_id, JOY_AXIS_1)
		if abs(horiz) > JOUST_AXI_THRESHOLD or abs(vert) > JOUST_AXI_THRESHOLD:
			joy_direction = Vector2(horiz, vert).normalized()

	if idle and event.is_action("joust") and event.pressed:
		charge_joust()
	elif charging_joust and event.is_action("joust") and !event.pressed:
		joust_attack()
	if idle and event.is_action("dodge") and event.pressed:
		dodge()
	elif idle and event.is_action("parry") and event.pressed:
		parry()
	check_for_move_event(event, "up")
	check_for_move_event(event, "right")
	check_for_move_event(event, "down")
	check_for_move_event(event, "left")


func _physics_process(delta):
	if get_tree().network_peer and !is_network_master():
		return
	if charging_joust:
		joust_indicator_charge += JOUST_CHARGE_RATE * delta
		joust_indicator_charge = min(joust_indicator_charge, MAX_JOUST_CHARGE)
		update_joust_indicator()

	var movement
	if locked:
		movement = get_locked_movement()
	else:
		movement = get_input_movement()
	var _vel = move_and_slide(movement)
	update_sprite_direction(movement)
	
	if joust_attacking:
		deplete_joust_charge(movement.length() * delta)
	
	if get_tree().network_peer:
		rset_unreliable("position", position)


func get_locked_movement():
	return locked_direction.normalized() * locked_speed


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
	if movement.length() > 0:
		last_direction = movement.normalized()
	if movement.length() > 1:
		movement = movement.normalized()
	if slowed:
		movement *= slowed_speed
	else:
		movement *= SPEED
	return movement


func charge_joust():
	locked_direction = Vector2(0, 0)
	joy_direction = last_direction
	joust_indicator_charge = 0.0
	update_joust_indicator()
	$Knight_Animator.play("Charging_Joust")
	$Turtle_Animator.play("Charging_Joust")


func joust_attack():
	locked_direction = joy_direction.normalized()
	joust_charge = joust_indicator_charge * JOUST_CHARGE_DIST_MODIFIER
	$Knight_Animator.play("Joust")
	$Turtle_Animator.play("Joust")


func dodge():
	locked_direction = last_direction
	$Knight_Animator.play("Dodge")
	$Knight_Animator.queue("Idle_Knight")
	$Turtle_Animator.play("Dodge")
	$Turtle_Animator.queue("Idle")


func parry():
	locked_direction = Vector2(0, 0)
	$Knight_Animator.play("Parry")
	$Knight_Animator.queue("Idle_Knight")
	$Turtle_Animator.play("Parry")
	$Turtle_Animator.queue("Idle")


func update_joust_indicator():
	var direct = joy_direction.normalized()
	var angle = direct.angle()
	$JoustIndicatorBottom.position = direct * JOUST_INDICATOR_RADIUS
	$JoustIndicatorBottom.rotation = angle + PI / 2
	var tip_radius = JOUST_INDICATOR_RADIUS + joust_indicator_charge
	$JoustIndicator.position = direct * tip_radius
	$JoustIndicator.rotation = angle + PI / 2


func update_sprite_direction(movement):
	if (idle and movement.x > 1) or (locked and !locked_direction and joy_direction.x > 0.1):
		$Sprite.scale.x = abs($Sprite.scale.x)
		$LanceHitbox.scale.x = abs($LanceHitbox.scale.x)
		$KnightHitbox.scale.x = abs($KnightHitbox.scale.x)
		$TurtleHitbox.scale.x = abs($TurtleHitbox.scale.x)
	elif (idle and movement.x < -1) or (locked and !locked_direction and joy_direction.x < -0.1):
		$Sprite.scale.x = -abs($Sprite.scale.x)
		$LanceHitbox.scale.x = -abs($LanceHitbox.scale.x)
		$KnightHitbox.scale.x = -abs($KnightHitbox.scale.x)
		$TurtleHitbox.scale.x = -abs($TurtleHitbox.scale.x)
	if get_tree().network_peer:
		$Sprite.rset("scale", $Sprite.scale)
		$LanceHitbox.rset("scale", $LanceHitbox.scale)
		$KnightHitbox.rset("scale", $KnightHitbox.scale)
		$TurtleHitbox.rset("scale", $TurtleHitbox.scale)


func deplete_joust_charge(dist_travelled):
	joust_charge -= dist_travelled
	if joust_charge <= 0.0:
		$Knight_Animator.play("Idle_Knight")
		$Turtle_Animator.play("Idle")

func check_for_move_event(event, direction):
	if event.is_action("move_" + direction):
		if event is InputEventJoypadMotion:
			if direction == "right" or direction == "down":
				if event.axis_value > MOVE_AXI_THRESHOLD:
					movement_actions[direction][1] = event.axis_value
				else:
					movement_actions[direction][1] = 0
			else:
				if event.axis_value < -MOVE_AXI_THRESHOLD:
					movement_actions[direction][1] = abs(event.axis_value)
				else:
					movement_actions[direction][1] = 0
		else: 
			movement_actions[direction][0] = event.is_pressed()
			if event.pressed:
				match direction:
					"up":
						joy_direction = Vector2(0, -1)
					"right":
						joy_direction = Vector2(1, 0)
					"down":
						joy_direction = Vector2(0, 1)
					"left":
						joy_direction = Vector2(-1, 0)
					


func load_data(data = {}):
	device_id = data.get("device_id", null)


func invert_start_direction():
	$Sprite.scale.x *= -1
	$LanceHitbox.scale.x *= -1
	$KnightHitbox.scale.x *= -1
	$TurtleHitbox.scale.x *= -1
	update_sprite_direction(Vector2(0, 0))
	last_direction.x *= -1
	joy_direction.x *= -1


func set_indicator_visibility(visibility):
	if get_tree().network_peer and !is_network_master():
		return
	$JoustIndicator.visible = visibility
	$JoustIndicatorBottom.visible = visibility


func _on_Knight_Animator_animation_started(anim_name):
	if get_tree().network_peer:
		rpc("_set_knight_animation", anim_name)


func _on_Turtle_Animator_animation_started(anim_name):
	if get_tree().network_peer:
		rpc("_set_turtle_animation", anim_name)
		

remote func _set_knight_animation(anim_name):
	if $Knight_Animator.current_animation == anim_name:
		return
	$Knight_Animator.play(anim_name)


remote func _set_turtle_animation(anim_name):
	if $Turtle_Animator.current_animation == anim_name:
		return
	$Turtle_Animator.play(anim_name)


func _on_LanceHitbox_hit_something():
	$Knight_Animator.play("Idle_Knight")
	$Turtle_Animator.play("Idle")


func _on_hit_fellow_turtle():
	if joust_attacking:
		$Knight_Animator.play("Idle_Knight")
		$Turtle_Animator.play("Idle")
		

func make_collisions_unique():
	$CollisionShape2D.shape= $CollisionShape2D.shape.duplicate()
	var lance_col = $LanceHitbox/CollisionShape2D
	lance_col.shape = lance_col.shape.duplicate()
	var knight_col = $KnightHitbox/CollisionShape2D
	knight_col.shape = knight_col.shape.duplicate()
	var turtle_col = $TurtleHitbox/CollisionShape2D
	turtle_col.shape = turtle_col.shape.duplicate()
