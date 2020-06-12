extends Control


signal lifted_up

var object_to_call
var method_to_call


# Bring down the visor, call obj's method when done
remote func bring_down(obj, method):
	object_to_call = obj
	method_to_call = method
	$AnimationPlayer.play("down")


# Will call the obj's method
func _down_done():
	object_to_call.call(method_to_call)


# Bring up the visor
remote func lift_up():
	$AnimationPlayer.play("up")


# Emit signal when visor brought up
func lift_up_done():
	emit_signal("lifted_up")
