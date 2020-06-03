extends "res://weapons/weapon.gd"


const LARGE_KNOCKBACK = 400
const MEDIUM_KNOCKBACK = 300
const MAX_DAMAGE = 100
const LARGE_DAMAGE = 60
const SMALL_DAMAGE = 15


func _hit_knight(knight):
	._hit_knight(knight)
	var forwards = knight.global_position - knight_held_by.global_position
	var medium_knockback = forwards.normalized() * MEDIUM_KNOCKBACK
	var large_knockback = forwards.normalized() * LARGE_KNOCKBACK
	if knight.parrying:
		player_held_by.call_deferred("knock_knight_off", -large_knockback)
		knight.call_deferred("hit", SMALL_DAMAGE, medium_knockback)
	else:
		player_held_by.call_deferred("knock_knight_off", -medium_knockback)
		if !knight.on_turtle:
			knight.call_deferred("hit", MAX_DAMAGE)
		else:
			knight.call_deferred("hit", LARGE_DAMAGE, large_knockback)
			if knight.health > LARGE_DAMAGE:
				knight.get_parent().call_deferred("knock_knight_off", large_knockback)
	get_parent().call_deferred("unequip_held_weapon")


func _hit_weapon(weapon):
	var forwards = weapon.knight_held_by.global_position - knight_held_by.global_position
	var medium_knockback = forwards.normalized() * MEDIUM_KNOCKBACK
	var large_knockback = forwards.normalized() * LARGE_KNOCKBACK
	player_held_by.call_deferred("knock_knight_off", -medium_knockback)
	get_parent().unequip_held_weapon()
	weapon.knight_held_by.call_deferred("hit", LARGE_DAMAGE)
	if weapon.knight_held_by.health > LARGE_DAMAGE:
		weapon.player_held_by.call_deferred("knock_knight_off", large_knockback)
	
