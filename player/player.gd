extends "res://player/turtle/turtle.gd"


signal lost

const JOUST_DEADZONE = 0.7  # Min length of movement to count
const JOUST_CHARGE_RATE = 250
const MAX_JOUST_CHARGE = 500
const MOUSE_SENSITIVITY = 0.01
const LOST_DUEL_KNOCKBACK = 100
const duel_indicator_scene = preload("res://player/duel_indicator/duel_indicator.tscn")

var joust_charge = 0.0
var joust_direction = Vector2(1, 0)
var dueling = false
var number


# Handle different actions
func _input(event):
	if !_should_handle_event(event):
		return false
	
	if !has_node("Knight"):
		return
	
	if $Knight/AnimationTree.is_in_state("idle"):
		if event.is_action_pressed("joust"):
			begin_charging_joust()
		if event.is_action_pressed("dodge"):
			dodge()
		if event.is_action_pressed("parry"):
			parry()
	elif $Knight/AnimationTree.is_in_state("charging_joust"):
		if event.is_action_released("joust"):
			release_joust()
		elif event is InputEventMouseMotion:
			joust_direction += event.relative * MOUSE_SENSITIVITY
			joust_direction = joust_direction.clamped(1)


# Update jousting mechanics
func _physics_process(delta):
	if !_should_process():
		return
	
	if $AnimationTree.is_in_state("charging_joust"):
		joust_charge += JOUST_CHARGE_RATE * delta
		joust_charge = min(joust_charge, MAX_JOUST_CHARGE)
		update_joust_indicator()
	elif $AnimationTree.is_in_state("jousting"):
		joust_charge -= locked_speed * delta
		if joust_charge <= 0.0:
			$AnimationTree.travel("idle")
			$Knight/AnimationTree.travel("joust_ending")


# Begin to charge up joust
func begin_charging_joust():
	$Knight/AnimationTree.travel("charging_joust")
	$AnimationTree.travel("charging_joust")
	joust_charge = 0.0
	joust_direction = last_direction
	reset_movement_presses()
	$JoustIndicator.visible = true
	update_joust_indicator()


# Joust attack
func release_joust():
	$Knight/AnimationTree.travel("jousting")
	$AnimationTree.travel("jousting")
	$JoustIndicator.visible = false
	locked_direction = joust_direction


# Dodge out of the way
func dodge():
	$Knight/AnimationTree.travel("dodging")
	$AnimationTree.travel("dodging")
	locked_direction = last_direction


# Parry oncoming attacks
func parry():
	$Knight/AnimationTree.travel("parrying")
	$AnimationTree.travel("parrying")


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
		$Knight/AnimationTree.travel("dueling")
	$JoustIndicator.visible = false


# Player won the duel, just go back to idle
func won_duel():
	dueling = false
	$Knight/AnimationTree.travel("idle")
	$AnimationTree.travel("idle")


# Player lost the duel, knock them off
func lost_duel(knockback_dir):
	dueling = false
	knock_knight_off(knockback_dir * LOST_DUEL_KNOCKBACK)


# Update position and rotation of joust indicator while charging joust
func update_joust_indicator():
	var h = movement_actions["right"][1] - movement_actions["left"][1]
	h += int(movement_actions["right"][0]) - int(movement_actions["left"][0])
	var v = movement_actions["down"][1] - movement_actions["up"][1]
	v += int(movement_actions["down"][0]) - int(movement_actions["up"][0])
	var dir = Vector2(h, v)
	if dir.length() > JOUST_DEADZONE:
		joust_direction = dir.normalized()
	
	$JoustIndicator.update_indicator(joust_direction, joust_charge)


# Extend update_sprite_direction to consider joust direction
func update_sprite_direction(movement):
	var jousting = false
	if has_node("Knight"):
		jousting = $Knight/AnimationTree.is_in_state("charging_joust")
	if movement.x > 1 or (jousting and sign(joust_direction.x) == 1):
		set_direction(1)
	elif movement.x < -1 or (jousting and sign(joust_direction.x) == -1):
		set_direction(-1)


# Check to move between idle and moving animation
func moved(movement):
	if has_node("Knight"):
		$Knight.moved(movement)
	
	if movement and $AnimationTree.is_in_state("idle"):
		$AnimationTree.travel_idle("idle_moving")
		last_direction = movement.normalized()
	elif !movement and $AnimationTree.is_in_state("idle"):
		$AnimationTree.travel_idle("idle_resting")


# Remove knight from self
func knock_knight_off(knockback):
	if !has_node("Knight"):
		return
	var knight = get_node("Knight")
	remove_child(knight)
	get_parent().add_child(knight)
	knight.global_position = global_position + knockback
	knight.get_node("AnimationTree").travel("flying_off")
	$AnimationTree.travel("idle")
	

# Add knight back
func pick_up_knight(knight):
	knight.in_water = false
	knight.get_node("AnimationTree").travel("mounting")
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
	if has_node("Knight"):
		$Knight.set_direction(dir_sign)


# Stop joust when hit another turtle
func hit_turtle(turtle):
	if !has_node("Knight") or !turtle.has_node("../Knight"):
		return

	var other_knight = turtle.get_node("../Knight")
	if other_knight.get_node("AnimationTree").is_in_state("mounting"):
		return
	if $Knight.held_weapon.areas_hit.has(other_knight):
		return
	
	if $Knight/AnimationTree.is_in_state("jousting"):
		call_deferred("duel", turtle.get_parent(), true)


# Pickup knight if hit and in water
func hit_knight(knight):
	if knight.in_water and knight.alive and number == knight.player_number:
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
