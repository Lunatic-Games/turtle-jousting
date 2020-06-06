extends "res://weapons/weapon.gd"


const KNOCKBACK = 200


func sweep():
	var direction = sign(player_held_by.get_node("Reversable").scale.x)
	var g_pos = player_held_by.global_position
	for player in get_tree().get_nodes_in_group("player"):
		if player != player_held_by:
			if (direction == 1 and player.global_position.x > g_pos.x):
				sweep_player_off(player)
			elif (direction == -1 and player.global_position.x < g_pos.x):
				sweep_player_off(player)


func sweep_player_off(player):
	var direction = player.global_position - player_held_by.global_position
	direction = direction.normalized()
	player.knock_knight_off(direction * KNOCKBACK)


func sweep_done():
	_unequip()
