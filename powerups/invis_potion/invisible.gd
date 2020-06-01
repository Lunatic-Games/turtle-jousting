extends "res://powerups/status.gd"


func _ready():
	player.get_node("Reversable").visible = false
	player.get_node("Knight").visible = false


func _on_DurationTimer_timeout():
	player.get_node("Reversable").visible = true
	player.get_node("Knight").visible = true
