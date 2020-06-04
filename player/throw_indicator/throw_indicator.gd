extends Node2D


const COLOR = Color(0.5, 0.5, 0.5, 0.4)
const WIDTH = 2
const AA = false

var charge = 0.0
var curve


# Set the Curve2D using for displaying the trajectory
func set_curve(new_curve):
	curve = new_curve


# Update indicator with new charge amount
func update_indicator(new_charge):
	charge = new_charge
	update()


# Draw throw arc
func _draw():
	if !curve:
		return
	var points = []
	var scale = charge / curve.interpolate_baked(curve.get_baked_length()).x
	for i in range(curve.get_baked_length()):
		var point = curve.interpolate_baked(i)
		point.x *= scale
		points.push_back(point)
	draw_polyline(points, COLOR, WIDTH, AA)
