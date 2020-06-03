extends "res://weapons/weapon.gd"


export (float) var SPEED = 0
export (Curve) var HEIGHT_CURVE

var thrown = false
var travel
var distance_travelled


func throw(travel_vec):
	$CollisionShape2D.disabled = false
	travel = travel_vec
	distance_travelled = 0
	thrown = true
	
	
func _physics_process(delta):
	var movement = travel.normalized() * SPEED * delta
	position += travel.normalized() * SPEED * delta
