extends Control


signal lifted_up
signal brought_down


func bring_down():
	$AnimationPlayer.play("down")
	
	
func lift_up():
	$AnimationPlayer.play("up")
