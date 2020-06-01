extends "res://powerups/powerup.gd"


const effect_scene = preload("res://powerups/lightning_rod/lightning_prone.tscn")


func pick_up(player):
	.pick_up(player)
	var effect = effect_scene.instance()
	effect.player = player
