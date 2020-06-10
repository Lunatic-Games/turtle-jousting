extends "res://powerups/status.gd"


func _ready():
	player.get_node("Knight/AnimationTree").travel("stoning")
	player.get_node("Knight").weapon_handle.unequip_held_weapon()
	player.remove_status("Drunk")
