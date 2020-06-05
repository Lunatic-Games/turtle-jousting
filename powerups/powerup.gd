extends Area2D


signal picked_up

export (PackedScene) var status
export (PackedScene) var weapon


# Players will call this when they pick it up
func pick_up(player):
	assert(player.has_node("Knight"))
	if status:
		var new_status = status.instance()
		new_status.player = player
		new_status.knight = player.get_node("Knight")
		player.add_status(new_status)
	if weapon:
		var new_weapon = weapon.instance()
		var weapon_handle = player.get_node("Knight").weapon_handle
		weapon_handle.call_deferred("equip", new_weapon)
	emit_signal("picked_up")
	call_deferred("queue_free")


# Queue the next two animations
func spawn_anim_done():
	$AnimationPlayer.play("open_tier2")
	$AnimationPlayer.queue("shine")
