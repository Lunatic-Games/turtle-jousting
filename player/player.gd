extends "res://player/turtle/turtle.gd"


signal lost
signal began_duel
signal duel_ended

export (Curve) var joust_velocity

const JOUST_DEADZONE = 0.7  # Min length of movement to count
const JOUST_CHARGE_RATE = 600
const MAX_JOUST_CHARGE = 1500
const THROW_START_CHARGE = 150
const THROW_CHARGE_RATE = 150
const MAX_THROW_CHARGE = 800
const MOUSE_SENSITIVITY = 0.01
const LOST_DUEL_KNOCKBACK = 200
const duel_indicator_scene = preload("res://player/duel_indicator/duel_indicator.tscn")
const bot_ai_scene = preload("res://player/bot_ai.tscn")

var joust_initial_charge = 0.0
var joust_charge = 0.0
var joust_direction = Vector2(1, 0)
var joust_move_actions
var throw_charge = 0.0
var dueling = false
onready var knight = get_node("Knight")


func _ready():
	if get_tree().network_peer and is_network_master():
		rpc("set_color", $Reversable/Sprite/Modulate.modulate)
	if get_tree().network_peer:
		rpc_config("call_deferred", MultiplayerAPI.RPC_MODE_REMOTE)


# Handle different actions
func _input(event):
	if !_should_handle_event(event):
		return false
	
	if !has_node("Knight"):
		return
	
	if $Knight/AnimationTree.is_in_state("controlling/waiting"):
		if (event.is_action_pressed("joust") 
				and $Knight.weapon_handle.weapon.can_joust):
			begin_charging_joust()
		if (event.is_action_pressed("joust") 
				and $Knight.weapon_handle.weapon.is_in_group("throwable")):
			begin_charging_throw()
		if (event.is_action_pressed("joust")
				and $Knight.weapon_handle.weapon.can_sweep):
			$Knight/AnimationTree.travel("controlling/sweeping")
		if event.is_action_pressed("dodge"):
			dodge()
		if event.is_action_pressed("parry"):
			parry()
	elif has_status("Stoned") and event.is_action_pressed("joust"):
		begin_charging_joust()
	elif $AnimationTree.is_in_state("controlling/jousting/charging_joust"):
		if event.is_action_released("joust"):
			release_joust()
		elif event is InputEventMouseMotion:
			joust_direction += event.relative * MOUSE_SENSITIVITY
			joust_direction = joust_direction.clamped(1)
	elif $Knight/AnimationTree.is_in_state("controlling/throwing/charging_throw"):
		if event.is_action_released("joust"):
			release_throw()


# Update jousting mechanics
func _physics_process(delta):
	if !_should_process():
		return
	
	if $AnimationTree.is_in_state("controlling/jousting/charging_joust"):
		joust_charge += JOUST_CHARGE_RATE * delta
		joust_charge = min(joust_charge, MAX_JOUST_CHARGE)
		update_joust_indicator()
	
	elif (has_node("Knight") 
			and $Knight/AnimationTree.is_in_state("controlling/throwing/charging_throw")):
		throw_charge += THROW_CHARGE_RATE * delta
		throw_charge = min(throw_charge, MAX_THROW_CHARGE)
		$ThrowIndicator.update_indicator(throw_charge)
	
	elif $AnimationTree.is_in_state("controlling/jousting/jousting"):
		joust_charge -= locked_speed * delta
		if joust_charge <= 0.0:
			$AnimationTree.travel("controlling/waiting/idling")
			if has_status("Stoned"):
				$Knight.weapon_handle.disable_hitbox()
			if $Knight/AnimationTree.is_in_state("controlling/jousting/jousting"):
				$Knight/AnimationTree.travel("controlling/jousting/joust_ending")
		else:
			calculate_joust_locked_speed()


# Begin to charge up joust
func begin_charging_joust():
	if !has_status("Stoned"):
		$Knight/AnimationTree.travel("controlling/jousting/charging_joust")
	$AnimationTree.travel("controlling/jousting/charging_joust")
	joust_charge = 0.0
	joust_direction = last_direction
	joust_move_actions = {"up": [false, 0], "right": [false, 0],
		"down": [false, 0], "left": [false, 0]}
	$JoustIndicator.visible = true
	update_joust_indicator()


# Joust attack
func release_joust():
	if has_status("Stoned"):
		$Knight.weapon_handle.reset_areas_hit()
		$Knight.weapon_handle.new_attack()
	else:
		$Knight/AnimationTree.travel("controlling/jousting/jousting")
	$AnimationTree.travel("controlling/jousting/jousting")
	$JoustIndicator.visible = false
	if $Knight.weapon_handle.weapon.name == "Lance":
		$Knight.weapon_handle.weapon.charge = joust_charge / MAX_JOUST_CHARGE
	$Knight.weapon_handle.weapon.angle = joust_direction.angle()
	joust_initial_charge = joust_charge
	locked_direction = joust_direction
	calculate_joust_locked_speed()


# Follow joust velocity curve
func calculate_joust_locked_speed():
	var dist = joust_initial_charge - joust_charge
	var ratio = dist / joust_initial_charge
	locked_speed = joust_velocity.interpolate(ratio)


# Begin to charge up your throw
func begin_charging_throw():
	$Knight/AnimationTree.travel("controlling/throwing/charging_throw")
	$AnimationTree.travel("controlling/waiting/idling")
	throw_charge = THROW_START_CHARGE
	$ThrowIndicator.set_curve($Knight.weapon_handle.weapon.get_curve())
	$ThrowIndicator.update_indicator(throw_charge)
	$ThrowIndicator.visible = true


# Throw held weapon
func release_throw():
	$Knight/AnimationTree.travel("controlling/throwing/throwing")
	assert($Knight.weapon_handle.weapon.is_in_group("throwable"))
	$Knight.weapon_handle.throw_held_weapon(throw_charge, 
		sign($ThrowIndicator.scale.x))
	$ThrowIndicator.visible = false


# Dodge out of the way
func dodge():
	$Knight/AnimationTree.travel("controlling/dodging")
	$AnimationTree.travel("controlling/dodging")
	locked_direction = last_direction


# Parry oncoming attacks
func parry():
	$Knight/AnimationTree.travel("controlling/parrying")
	$AnimationTree.travel("controlling/parrying")


# Duel with an enemy
func duel(opponent):
	if opponent.dueling or !has_node("Knight") or !opponent.has_node("Knight"):
		return
	knight.set_direction(sign(opponent.knight.global_position.x 
		- knight.global_position.x))
	opponent.knight.set_direction(sign(knight.global_position.x
		- opponent.knight.global_position.x))
	var duel_indicator = duel_indicator_scene.instance()
	get_parent().add_child(duel_indicator)
	duel_indicator.display(self, opponent)
	begin_dueling(duel_indicator)
	opponent.begin_dueling(duel_indicator)


# Setup required for both players of a duel
func begin_dueling(indicator):
	dueling = true
	$AnimationTree.travel("dueling")
	$Knight/AnimationTree.travel("controlling/jousting/dueling")
	$JoustIndicator.visible = false
	emit_signal("began_duel", indicator)


# Player won the duel, just go back to idle
func won_duel():
	dueling = false
	$Knight/AnimationTree.travel("controlling/waiting/idling")
	$AnimationTree.travel("controlling/waiting/idling")
	emit_signal("duel_ended")


# Player lost the duel, knock them off
func lost_duel(knockback_dir):
	dueling = false
	knock_knight_off(knockback_dir * LOST_DUEL_KNOCKBACK)
	emit_signal("duel_ended")


# Update position and rotation of joust indicator while charging joust
func update_joust_indicator():
	var h = joust_move_actions["right"][1] - joust_move_actions["left"][1]
	h += int(joust_move_actions["right"][0]) - int(joust_move_actions["left"][0])
	var v = joust_move_actions["down"][1] - joust_move_actions["up"][1]
	v += int(joust_move_actions["down"][0]) - int(joust_move_actions["up"][0])
	var dir = Vector2(h, v)
	if dir.length() > JOUST_DEADZONE:
		joust_direction = dir.normalized()
	
	$JoustIndicator.update_indicator(joust_direction, 
		joust_charge / MAX_JOUST_CHARGE)


# Extend update_sprite_direction to consider joust direction
func update_sprite_direction(movement):
	if has_node("Knight") and $Knight/AnimationTree.is_in_state("controlling/throwing"):
		return
	var jousting = $AnimationTree.is_in_state("controlling/jousting/charging_joust")
	if movement.x > 1 or (jousting and sign(joust_direction.x) == 1):
		set_direction(1)
	elif movement.x < -1 or (jousting and sign(joust_direction.x) == -1):
		set_direction(-1)


# Check to move between idle and moving animation
func moved(movement):
	if has_node("Knight"):
		$Knight.moved(movement)
	
	if movement and $AnimationTree.is_in_state("controlling/waiting/idling"):
		$AnimationTree.travel("controlling/waiting/moving")
		last_direction = movement.normalized()
	elif !movement and $AnimationTree.is_in_state("controlling/waiting/moving"):
		$AnimationTree.travel("controlling/waiting/idling")


# Remove knight from self
remote func knock_knight_off(knockback):
	if !has_node("Knight"):
		return
	if get_tree().network_peer:
		rpc("knock_knight_off", knockback)
	var prev_pos = knight.global_position
	remove_child(knight)
	get_parent().add_child(knight)
	knight.global_position = prev_pos
	knight.fly_off(knockback)
	$AnimationTree.travel("controlling/waiting")
	$JoustIndicator.visible = false
	$ThrowIndicator.visible = false
	if has_status("Drunk"):
		remove_status("Drunk")
	elif has_status("Stoned"):
		knight.hit(100)


# Add knight back
remote func pick_up_knight():
	if has_node("Knight"):
		return
	if get_tree().network_peer:
		rpc("pick_up_knight")
	knight.on_turtle = true
	knight.get_node("AnimationTree").travel("flying_off/mounting")
	knight.get_parent().remove_child(knight)
	add_child(knight)
	knight.name = "Knight"
	knight.position = $Reversable/KnightPosition.position


# Load player data
func load_data(data = {}):
	if data.get("bot_id", null) != null:
		device_id = data.get("bot_id", null)
		add_child(bot_ai_scene.instance())
	else:
		device_id = data.get("device_id", null)
	if data.get("color", null):
		set_color(data["color"])


# Set facing direction
func set_direction(dir_sign):
	.set_direction(dir_sign)
	$ThrowIndicator.scale.x = dir_sign * abs($ThrowIndicator.scale.x)
	if has_node("Knight"):
		$Knight.set_direction(dir_sign)


# Stop joust when hit another turtle
func hit_turtle(turtle):
	if !$AnimationTree.is_in_state("controlling/jousting/jousting"):
		return
	var angle = (turtle.global_position - global_position).angle()
	if angle < PI / 5 and angle > -PI / 5:
		locked_direction.x = -abs(locked_direction.x)
	if angle >= PI / 5 and angle < 4 * PI / 5:
		locked_direction.y = -abs(locked_direction.y)
	if angle >= 4 * PI / 5 or angle <= -4 * PI / 5:
		locked_direction.x = abs(locked_direction.x)
	if angle < -PI / 5 and angle > -4 * PI / 5:
		locked_direction.y = abs(locked_direction.y)


# Pickup knight if hit and in water
func hit_knight(knight_hit):
	if knight_hit == knight and !knight.on_turtle and knight.alive:
		call_deferred("pick_up_knight")


# Bounce off walls if jousting
func hit_wall(wall):
	if !$AnimationTree.is_in_state("controlling/jousting/jousting"):
		return
	if wall.is_in_group("east_wall"):
		locked_direction.x = -abs(locked_direction.x)
	elif wall.is_in_group("north_wall"):
		locked_direction.y = abs(locked_direction.y)
	elif wall.is_in_group("south_wall"):
		locked_direction.y = -abs(locked_direction.y)
	elif wall.is_in_group("west_wall"):
		locked_direction.x = abs(locked_direction.x)
	$Knight.weapon_handle.weapon.reset_areas_hit()
	$Knight.weapon_handle.weapon.angle = locked_direction.angle()


# Pick up a powerup, if able
func hit_powerup(powerup):
	if has_node("Knight") and !has_status("Stoned"):
		powerup.pick_up(self)


# Set color modulation for team color
remote func set_color(color):
	.set_color(color)
	$JoustIndicator.set_color(color)
	$Knight.set_color(color)


# Stop taking input and don't count self as player
func _on_Knight_died():
	set_process_input(false)
	remove_from_group("player")
	emit_signal("lost")


# Add a status to the player
func add_status(status):
	if $Statuses.has_node(status.name):
		$Statuses.get_node(status.name).refresh()
	else:
		$Statuses.add_child(status)


# Remove a status from the player
func remove_status(status_name):
	if $Statuses.has_node(status_name):
		$Statuses.get_node(status_name).queue_free()


# Return true if you have a status
func has_status(status_name):
	return $Statuses.has_node(status_name)


# Update joust move actions when changed
func _on_movement_actions_changed(direction, type, value):
	if joust_move_actions:
		joust_move_actions[direction][type] = value
