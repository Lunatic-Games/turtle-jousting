extends Area2D


signal picked_up

export (PackedScene) var status


# Players will call this when they pick it up
func pick_up(player):
	if status:
		var new_status = status.instance()
		new_status.player = player
		player.add_status(new_status)
	emit_signal("picked_up")
	call_deferred("queue_free")


func spawn_anim_done():
	$AnimationPlayer.play("open_tier1")
	$AnimationPlayer.queue("shine")
