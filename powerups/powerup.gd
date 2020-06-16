extends Area2D


signal picked_up

export (PackedScene) var status
export (PackedScene) var weapon
export (Array, Resource) var audio_on_pickup


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
	play_audio()
	call_deferred("queue_free")


# Queue the next two animations
func spawn_anim_done():
	$AnimationPlayer.play("open_tier2")
	$AnimationPlayer.queue("shine")


func play_audio():
	var audio = audio_on_pickup[randi() % len(audio_on_pickup)]
	var player = AudioStreamPlayer.new()
	player.connect("finished", player, "queue_free")
	player.stream = audio
	get_parent().add_child(player)
	player.playing = true
