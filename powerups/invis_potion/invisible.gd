extends "res://powerups/status.gd"


func _ready():
	player.get_node("Reversable").visible = false
	knight.visible = false


func _on_DurationTimer_timeout():
	player.get_node("Reversable").visible = true
	knight.visible = true
