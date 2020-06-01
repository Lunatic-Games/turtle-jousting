extends "res://powerups/status.gd"


const STRUCK_SPEED_MODIFIER = 2.0


func _ready():
	$AnimationPlayer.play("flash")


func refresh():
	$AnimationPlayer.play("flash")
	$DurationTimer.start()


func _on_DurationTimer_timeout():
	player.speed_modifier = 1


func _on_StrikeTimer_timeout():
	$AnimationPlayer.play("flash")


func _set_lightning_position():
	$CanvasLayer/LightningBolt.position.x = player.global_position.x
	

func _begin_speed_up():
	$DurationTimer.start(0)
	player.speed_modifier = STRUCK_SPEED_MODIFIER
