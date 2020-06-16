extends "res://weapons/weapon.gd"


export (float) var SPEED = 0

var thrown = false
var charge
var distance_travelled
var dir_sign


# Begin the throw with given charge, throw_direction is -1 or 1
remote func throw(throw_charge, throw_direction):
	$CollisionShape2D.disabled = false
	distance_travelled = 0
	thrown = true
	charge = throw_charge
	dir_sign = throw_direction
	scale.x = throw_direction * abs(scale.x)
	if get_tree().network_peer and is_network_master():
		rpc("throw", throw_charge, throw_direction)


# If thrown, fly through the air
func _physics_process(delta):
	if thrown:
		var curve = get_curve()
		var curve_length = curve.get_baked_length()
		var scale = charge / curve.interpolate_baked(curve_length).x
		var previous = curve.interpolate_baked(distance_travelled / scale)
		distance_travelled += SPEED * delta
		if distance_travelled / scale >= curve_length:
			$CollisionShape2D.disabled = true
			$AnimationPlayer.play("fade")
		var new = curve.interpolate_baked(distance_travelled / scale)
		previous.x *= scale * dir_sign
		new.x *= scale * dir_sign
		position += (new - previous)


# Get the trajectory curve
func get_curve():
	return $Trajectory.curve
