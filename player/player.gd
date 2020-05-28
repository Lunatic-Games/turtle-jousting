extends "res://player/turtle/turtle.gd"


const JOUST_DEADZONE = 0.7  # Min length of movement to count
const JOUST_CHARGE_RATE = 250
const MAX_JOUST_CHARGE = 500
const JOUST_INDICATOR_RATIO = 0.5  # Ratio of indic. length to charge amount
const JOUST_INDICATOR_INNER_RADIUS = 150

var joust_charge = 0.0
var joust_direction


func _ready():
	if DEBUG:
		set_color(Color.aquamarine)


# Handle different actions
func _input(event):
	if !_should_handle_event(event):
		return false
	
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
	$JoustIndicatorBase.visible = true
	$JoustIndicatorPoint.visible = true
	update_joust_indicator()


# Joust attack
func release_joust():
	$Knight/AnimationTree.travel("jousting")
	$AnimationTree.travel("jousting")
	$JoustIndicatorBase.visible = false
	$JoustIndicatorPoint.visible = false
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


# Update position and rotation of joust indicator while charging joust
func update_joust_indicator():
	var h = movement_actions["right"][1] - movement_actions["left"][1]
	h += int(movement_actions["right"][0]) - int(movement_actions["left"][0])
	var v = movement_actions["down"][1] - movement_actions["up"][1]
	v += int(movement_actions["down"][0]) - int(movement_actions["up"][0])
	var dir = Vector2(h, v)
	if dir.length() > JOUST_DEADZONE:
		joust_direction = dir.normalized()
	
	var angle = joust_direction.angle()
	var dist = JOUST_INDICATOR_INNER_RADIUS
	$JoustIndicatorBase.position = joust_direction.normalized() * dist
	$JoustIndicatorBase.rotation = angle + PI / 2
	dist += joust_charge * JOUST_INDICATOR_RATIO
	$JoustIndicatorPoint.position = joust_direction.normalized() * dist
	$JoustIndicatorPoint.rotation = angle + PI / 2


# Load player data
func load_data(data = {}):
	device_id = data.get("device_id", null)
	if data.get("color", null):
		set_color(data["color"])


# Set facing direction
func set_direction(dir_sign):
	.set_direction(dir_sign)
	$Knight.set_direction(dir_sign)
	

# Set color modulation for team color
func set_color(color):
	$JoustIndicatorBase/Modulate.modulate = color
	$JoustIndicatorPoint/Modulate.modulate = color
	$Knight.set_color(color)
