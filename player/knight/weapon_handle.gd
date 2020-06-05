extends Node2D


onready var weapon = $Lance
var player_owned_by
var damage_mod = 1


func set_player(player):
	player_owned_by = player
	weapon.pick_up(player)


func equip(new_weapon):
	if weapon == $Lance:
		weapon.put_away()
	weapon = new_weapon
	weapon.pick_up(player_owned_by)
	weapon.damage_mod = damage_mod
	add_child(weapon)


func unequip_held_weapon():
	if weapon == $Lance:
		return
	weapon.queue_free()
	weapon = $Lance
	weapon.pick_up(player_owned_by)


func throw_held_weapon(charge, dir_sign):
	var prev_position = weapon.global_position
	remove_child(weapon)
	player_owned_by.get_parent().add_child(weapon)
	weapon.global_position = prev_position
	weapon.scale = Vector2(0.05, 0.05)
	weapon.throw(charge, dir_sign)
	weapon = $Lance


func new_attack():
	assert(weapon != null)
	weapon.reset_areas_hit()


func enable_hitbox():
	assert(weapon != null)
	weapon.get_node("CollisionShape2D").disabled = false
	

func disable_hitbox():
	assert(weapon != null)
	weapon.get_node("CollisionShape2D").disabled = true


func set_damage_mod(mod):
	damage_mod = mod
	weapon.damage_mod = mod


func show_held_weapon():
	weapon.visible = true

