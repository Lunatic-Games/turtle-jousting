extends "res://player/turtle/turtle.gd"


signal lost

const JOUST_DEADZONE = 0.7  # Min length of movement to count
const JOUST_CHARGE_RATE = 250
const MAX_JOUST_CHARGE = 500
const THROW_START_CHARGE = 150
const THROW_CHARGE_RATE = 150
const MAX_THROW_CHARGE = 800
const MOUSE_SENSITIVITY = 0.01
const LOST_DUEL_KNOCKBACK = 100
const duel_indicator_scene = preload("res://player/duel_indicator/duel_indicator.tscn")

var joust_charge = 0.0
var joust_direction = Vector2(1, 0)
var joust_move_actions
var throw_charge = 0.0
var dueling = false
var number


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
		if event.is_action_pressed("dodge"):
			dodge()
		if event.is_action_pressed("parry"):
			parry()
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
			if $Knight/AnimationTree.is_in_state("controlling/jousting/jousting"):
				$Knight/AnimationTree.travel("controlling/jousting/joust_ending")


# Begin to charge up joust
func begin_charging_joust():
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
	$Knight/AnimationTree.travel("controlling/jousting/jousting")
	$AnimationTree.travel("controlling/jousting/jousting")
	$JoustIndicator.visible = false
	locked_direction = joust_direction


# Begin to charge up your throw
func begin_charging_throw():
	$Knight/AnimationTree.travel("controlling/throwing/charging_throw")
	$AnimationTree.travel("controlling/waiting/idling")
	throw_charge = THROW_START_CHARGE
	$ThrowIndicator.set_curve($Knight.weapon_handle.weapon.get_curve())
	$ThrowIndicator.update_indicator(throw_charge)


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
func duel(opponent, slapping=false):
	if opponent.dueling or !has_node("Knight") or !opponent.has_node("Knight"):
		return
	var duel_indicator = duel_indicator_scene.instance()
	get_parent().add_child(duel_indicator)
	duel_indicator.display(self, opponent)
	begin_dueling(slapping)
	opponent.begin_dueling(slapping)


# Setup required for both players of a duel
func begin_dueling(slapping):
	dueling = true
	$AnimationTree.travel("dueling")
	if slapping:
		$Knight/AnimationTree.travel("slapping")
	else:
		$Knight/AnimationTree.travel("controlling/jousting/dueling")
	$JoustIndicator.visible = false


# Player won the duel, just go back to idle
func won_duel():
	dueling = false
	$Knight/AnimationTree.travel("controlling/waiting/idling")
	$AnimationTree.travel("controlling/waiting/idling")


# Player lost the duel, knock them off
func lost_duel(knockback_dir):
	dueling = false
	knock_knight_off(knockback_dir * LOST_DUEL_KNOCKBACK)


# Update position and rotation of joust indicator while charging joust
func update_joust_indicator():
	var h = joust_move_actions["right"][1] - joust_move_actions["left"][1]
	h += int(joust_move_actions["right"][0]) - int(joust_move_actions["left"][0])
	var v = joust_move_actions["down"][1] - joust_move_actions["up"][1]
	v += int(joust_move_actions["down"][0]) - int(joust_move_actions["up"][0])
	var dir = Vector2(h, v)
	if dir.length() > JOUST_DEADZONE:
		joust_direction = dir.normalized()
	
	$JoustIndicator.update_indicator(joust_direction, joust_charge)


# Extend update_sprite_direction to consider joust direction
func update_sprite_direction(movement):
	if has_node("Knight") and $Knight/AnimationTree.is_in_state("controlling/throwing"):
		return
	var jousting = false
	if has_node("Knight"):
		jousting = $Knight/AnimationTree.is_in_state("controlling/jousting/charging_joust")
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
func knock_knight_off(knockback):
	if !has_node("Knight"):
		return
	var knight = get_node("Knight")
	var prev_pos = knight.global_position
	remove_child(knight)
	get_parent().add_child(knight)
	knight.global_position = prev_pos
	knight.fly_off(knockback)
	$AnimationTree.travel("controlling/waiting")
	

# Add knight back
func pick_up_knight(knight):
	knight.on_turtle = true
	knight.get_node("AnimationTree").travel("flying_off/mounting")
	knight.get_parent().remove_child(knight)
	add_child(knight)
	knight.name = "Knight"
	knight.position = $Reversable/KnightPosition.position


# Load player data
func load_data(data = {}):
	device_id = data.get("device_id", null)
	number = data.get("number", null)
	$Knight.player_number = number
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
	if !has_node("Knight") or !turtle.has_node("../Knight"):
		return

	var other_knight = turtle.get_node("../Knight")
	if other_knight.get_node("AnimationTree").is_in_state("flying_off/mounting"):
		return
	if $Knight.weapon_handle.weapon.areas_hit.has(other_knight):
		return
	
	if $Knight/AnimationTree.is_in_state("controlling/jousting/jousting"):
		call_deferred("duel", turtle.get_parent(), true)


# Pickup knight if hit and in water
func hit_knight(knight):
	if !knight.on_turtle and knight.alive and number == knight.player_number:
		print("Picking up knight")
		call_deferred("pick_up_knight", knight)


# Set color modulation for team color
func set_color(color):
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


# Update joust move actions when changed
func _on_movement_actions_changed(direction, type, value):
	if joust_move_actions:
		joust_move_actions[direction][type] = value
