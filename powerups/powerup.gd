extends Area2D


signal picked_up


# Players will call this when they pick it up
func pick_up():
	emit_signal("picked_up")
	call_deferred("queue_free")


func spawn_anim_done():
	$AnimationPlayer.play("open_tier1")
	$AnimationPlayer.queue("shine")
