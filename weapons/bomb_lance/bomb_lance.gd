extends "res://weapons/weapon.gd"


const LARGE_KNOCKBACK = 400
const MEDIUM_KNOCKBACK = 300
const MAX_DAMAGE = 100
const LARGE_DAMAGE = 60
const SMALL_DAMAGE = 15

var angle = 0


func _hit_knight(knight):
	._hit_knight(knight)
	if (overlaps_area(knight.weapon_handle.weapon) 
			and knight.weapon_handle.weapon.can_joust):
		print("Hit knight at same time weapons hit")
		return
	var forwards = Vector2(cos(angle), sin(angle))
	var medium_knockback = forwards.normalized() * MEDIUM_KNOCKBACK
	var large_knockback = forwards.normalized() * LARGE_KNOCKBACK
	
	if knight.parrying:
		_knock_off_knight(knight_held_by, -large_knockback)
		_damage_knight(knight, SMALL_DAMAGE, medium_knockback)
	else:
		_knock_off_knight(knight_held_by, -medium_knockback)
		if !knight.on_turtle:
			_damage_knight(knight, MAX_DAMAGE)
		else:
			_damage_knight(knight, LARGE_DAMAGE, large_knockback)
			_knock_off_knight(knight, large_knockback)
	_unequip()


func _hit_weapon(weapon):
	._hit_weapon(weapon)
	var forwards = Vector2(cos(angle), sin(angle))
	var medium_knockback = forwards.normalized() * MEDIUM_KNOCKBACK
	var large_knockback = forwards.normalized() * LARGE_KNOCKBACK
	
	_knock_off_knight(knight_held_by, -medium_knockback)
	_unequip()
	
	_damage_knight(weapon.knight_held_by, LARGE_DAMAGE, large_knockback)
	_knock_off_knight(weapon.knight_held_by, large_knockback)
	
