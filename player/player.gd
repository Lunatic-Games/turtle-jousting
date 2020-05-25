extends KinematicBody2D


signal dueling


export (bool) var charging_up_joust = false
export (bool) var locked = false
export (float) var locked_speed = 200
export (bool) var slowed = false
export (float) var slowed_speed = 100


const SPEED = 100
const MOVE_AXI_THRESHOLD = 0.1
const JOUST_AXI_THRESHOLD = 0.7
const MOUSE_SENSITIVITY = 0.01
const JOUST_INDICATOR_RADIUS = 150
const MAX_JOUST_CHARGE = 200
const JOUST_CHARGE_RATE = 150
const JOUST_CHARGE_DIST_MODIFIER = 2.5
const KNOCKED_OFF_DISTANCE = 100
const DEBUG = true

var number
var device_id
var locked_direction = Vector2(0, 0)
var last_direction = Vector2(1, 0)
var joust_direction = Vector2(1, 0)
var joust_indicator_charge = 0.0
var joust_charge = 0.0
var started_duel = false

# Keeps track of movement input [button_active, joystick strength]
var movement_actions = {"up" : [false, 0], "right" : [false, 0],
	 "down" : [false, 0], "left" : [false, 0]}


func _ready():
	make_collisions_unique()
	$AnimationTree.active = true
	$Knight/AnimationTree.active = true
	
	if get_tree().network_peer:
		rset_config("position", MultiplayerAPI.RPC_MODE_PUPPET)
		$Sprite.rset_config("flip_h", MultiplayerAPI.RPC_MODE_PUPPET)
		$Sprite.rset_config("offset", MultiplayerAPI.RPC_MODE_PUPPET)
		$CollisionShape2D.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		$Hitbox.rset_config("scale", MultiplayerAPI.RPC_MODE_PUPPET)
		
	if DEBUG:
		device_id = 0
		set_color(Color.aquamarine)
	else:
		set_process_input(false)


func _input(event):
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
		joust_direction += event.relative * MOUSE_SENSITIVITY
		joust_direction = joust_direction.clamped(1)

	if $AnimationTree.is_in_state("idle") and has_node("Knight"):
		if event.is_action_pressed("joust"):
			charge_joust()
		elif event.is_action_pressed("dodge"):
			dodge()
		elif event.is_action_pressed("parry"):
			parry()
	elif charging_up_joust:
		if event.is_action_released("joust"):
			joust_attack()

	check_for_move_event(event, "up")
	check_for_move_event(event, "right")
	check_for_move_event(event, "down")
	check_for_move_event(event, "left")
	
	
func _physics_process(delta):
	if get_tree().network_peer and !is_network_master():
		return
	if charging_up_joust:
		joust_indicator_charge += JOUST_CHARGE_RATE * delta
		joust_indicator_charge = min(joust_indicator_charge, MAX_JOUST_CHARGE)
		update_joust_indicator()

	var movement
	if locked:
		movement = get_locked_movement()
	else:
		movement = get_input_movement()
	if movement and $AnimationTree.is_resting():
		$AnimationTree.move()
	elif !movement and $AnimationTree.is_moving():
		$AnimationTree.stop_moving()
	var _vel = move_and_slide(movement)
	update_sprite_direction(movement)
	
	if $AnimationTree.is_in_state("jousting"):
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
	if movement.length() > 0.001:
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
	joust_direction = last_direction
	joust_indicator_charge = 0.0
	update_joust_indicator()
	$AnimationTree.charge_joust()


func joust_attack():
	locked_direction = joust_direction.normalized()
	joust_charge = joust_indicator_charge * JOUST_CHARGE_DIST_MODIFIER
	$AnimationTree.begin_joust()


func dodge():
	locked_direction = last_direction
	$AnimationTree.dodge()


func parry():
	locked_direction = Vector2(0, 0)
	$AnimationTree.parry()


func update_joust_indicator():
	var h = movement_actions["right"][1] - movement_actions["left"][1]
	var v = movement_actions["down"][1] - movement_actions["up"][1]
	var direction = Vector2(h, v)
	if direction.length() > JOUST_AXI_THRESHOLD:
		joust_direction = direction.normalized()
	var angle = joust_direction.angle()
	$JoustIndicatorBottom.position = joust_direction.normalized() * JOUST_INDICATOR_RADIUS
	$JoustIndicatorBottom.rotation = angle + PI / 2
	var tip_radius = JOUST_INDICATOR_RADIUS + joust_indicator_charge
	$JoustIndicator.position = joust_direction.normalized() * tip_radius
	$JoustIndicator.rotation = angle + PI / 2


func update_sprite_direction(movement):
	var idle = $AnimationTree.is_in_state("idle") or $AnimationTree.is_in_state("mounting")
	if ((idle and movement.x > 1) or 
			(locked and !locked_direction and joust_direction.x > 0.1)):
		set_direction(1)
	elif ((idle and movement.x < -1) or 
			(locked and !locked_direction and joust_direction.x < -0.1)):
		set_direction(-1)


func set_direction(dir_sign):
	$Sprite.flip_h = dir_sign != 1
	$Sprite.offset.x = -dir_sign * abs($Sprite.offset.x)
	$CollisionShape2D.scale.x = dir_sign * abs($CollisionShape2D.scale.x)
	$Hitbox.scale.x = dir_sign * abs($Hitbox.scale.x)
	if get_tree().network_peer:
		$Sprite.rset("flip_h", $Sprite.flip_h)
		$Sprite.rset("offset", $Sprite.offset)
		$CollisionShape2D.rset("scale", $CollisionShape2D.scale)
		$Hitbox.rset("scale", $Hitbox.scale)
	if has_node("Knight"):
		$Knight.set_direction(dir_sign)


func deplete_joust_charge(dist_travelled):
	joust_charge -= dist_travelled
	if joust_charge <= 0.0:
		$AnimationTree.idle()
		$AnimationTree.rest()


func check_for_move_event(event, direction):
	if event.is_action("move_" + direction):
		if event is InputEventJoypadMotion:
			var strength = event.get_action_strength("move_" + direction)
			movement_actions[direction][1] = strength
		else: 
			movement_actions[direction][0] = event.is_pressed()


func load_data(data = {}):
	device_id = data.get("device_id", null)
	number = data.get("number", null)
	$Knight.number = number
	if data.get("color", null):
		set_color(data["color"])


func invert_start_direction():
	set_direction(-1)
	last_direction.x *= -1
	joust_direction.x *= -1


func set_indicator_visibility(visibility):
	if get_tree().network_peer and !is_network_master():
		return
	$JoustIndicator.visible = visibility
	$JoustIndicatorBottom.visible = visibility


func _on_Knight_lance_duel(other_player):
	emit_signal("dueling", self, other_player)
	$AnimationTree.duel()


func _on_hit_fellow_turtle():
	if $AnimationTree.is_in_state("jousting"):
		$AnimationTree.rest()
		

func _knock_knight_off(direction):
	if !has_node("Knight"):
		return
	var knight = get_node("Knight")
	call_deferred("remove_child", knight)
	get_parent().call_deferred("add_child", knight)
	knight.set_deferred("global_position", 
		knight.global_position + direction * KNOCKED_OFF_DISTANCE)
	$AnimationTree.knight_flying_off()


func _pick_up_knight(knight):
	var dup = knight.duplicate()
	dup.name = "Knight"
	dup.in_water = false
	dup.position = $KnightPosition.position
	dup.number = knight.number
	dup.health = knight.health
	knight.queue_free()
	call_deferred("add_child", dup)
	$AnimationTree.call_deferred("knight_picked_up")


func won_duel():
	$AnimationTree.rest()


func lost_duel(knocked_off_direction):
	_knock_knight_off(knocked_off_direction)

	
func make_collisions_unique():
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	var hitbox_col = $Hitbox/CollisionShape2D
	hitbox_col.shape = hitbox_col.shape.duplicate()
	var lance_col = $Knight/Reversable/Lance/CollisionShape2D
	lance_col.shape = lance_col.shape.duplicate()
	var knight_col = $Knight/CollisionShape2D
	knight_col.shape = knight_col.shape.duplicate()
	
	
func set_process_input(process):
	if process:
		.set_process_input(true)
	else:
		.set_process_input(false)
		movement_actions["up"] = [false, 0]
		movement_actions["right"] = [false, 0]
		movement_actions["down"] = [false, 0]
		movement_actions["left"] = [false, 0]


func set_color(color):
	$JoustIndicator/Modulate.modulate = color
	$JoustIndicatorBottom/Modulate.modulate = color
	$Knight.set_color(color)


func _on_Hitbox_picked_up_powerup(powerup):
	print("I picked up a powerup: ", powerup)
