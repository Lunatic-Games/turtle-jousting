extends "res://powerups/powerup.gd"


func pick_up(player):
	assert(player.has_node("Knight"))
	var knight = player.get_node("Knight")
	for other_knight in get_tree().get_nodes_in_group("knight"):
		if knight == other_knight:
			continue
		else:
			other_knight.set_health(knight.health)
	.pick_up(player)
