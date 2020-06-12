extends Node2D


const INNER_RADIUS = 80
const MAX_CHARGE_DIST = 100
const BASE_START_SCALE = 0.075
const BASE_END_SCALE = 0.1
const POINT_START_SCALE = 0.025
const POINT_END_SCALE = 0.05

var base_diff = BASE_END_SCALE - BASE_START_SCALE
var point_diff = POINT_END_SCALE - POINT_START_SCALE


# Update rotation of indicator
func update_indicator(direction, charge_percent):
	var angle = direction.angle()
	var dist = INNER_RADIUS
	$Base.position = direction.normalized() * dist
	$Base.rotation = angle + PI / 2
	$Base.scale.x = base_diff * charge_percent + BASE_START_SCALE
	dist += charge_percent * MAX_CHARGE_DIST
	$Point.position = direction.normalized() * dist
	$Point.rotation = angle + PI / 2
	$Point.scale.y = point_diff * charge_percent + POINT_START_SCALE


# Set team color
func set_color(color):
	$Base/Modulate.modulate = color
	$Point/Modulate.modulate = color
