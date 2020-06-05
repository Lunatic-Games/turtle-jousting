extends Node2D


const INNER_RADIUS = 80
const CHARGE_RATIO = 0.25


# Update rotation of indicator
func update_indicator(direction, charge):
	var angle = direction.angle()
	var dist = INNER_RADIUS
	$Base.position = direction.normalized() * dist
	$Base.rotation = angle + PI / 2
	dist += charge * CHARGE_RATIO
	$Point.position = direction.normalized() * dist
	$Point.rotation = angle + PI / 2


# Set team color
func set_color(color):
	$Base/Modulate.modulate = color
	$Point/Modulate.modulate = color
