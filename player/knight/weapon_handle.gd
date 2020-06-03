extends Node2D


onready var weapon = $Lance
var player_owned_by


func set_player(player):
	player_owned_by = player
	weapon.set_player(player)


func equip(new_weapon):
	if weapon == $Lance:
		weapon.put_away()
	weapon = new_weapon
	weapon.set_player(player_owned_by)
	disable_hitbox()
	add_child(weapon)
	weapon.pick_up()


func unequip_held_weapon():
	if weapon == $Lance:
		return
	weapon.queue_free()
	weapon = $Lance
	weapon.pick_up()


func new_attack():
	assert(weapon != null)
	weapon.reset_areas_hit()


func enable_hitbox():
	assert(weapon != null)
	weapon.get_node("CollisionShape2D").disabled = false
	

func disable_hitbox():
	assert(weapon != null)
	weapon.get_node("CollisionShape2D").disabled = true
