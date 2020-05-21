extends Control


signal lifted_up
signal brought_down


func bring_down():
	$AnimationPlayer.play("down")
	
	
func brought_down_done():
	emit_signal("brought_down")
	
	
func lift_up():
	$AnimationPlayer.play("up")


func lift_up_done():
	emit_signal("lifted_up")
