extends "res://powerups/powerup.gd"


const bomb_lance_scene = preload("res://weapons/bomb_lance/bomb_lance.tscn")


func pick_up(player):
	var weapon_handle = player.get_node("Knight").weapon_handle
	weapon_handle.call_deferred("equip", bomb_lance_scene.instance())
	.pick_up(player)
