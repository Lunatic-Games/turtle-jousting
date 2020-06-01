extends "res://powerups/status.gd"


func _ready():
	player.get_node("Reversable").visible = false
	player.get_node("Knight").visible = false
