extends "res://weapons/weapon.gd"


const DAMAGE = 20
const KNOCKBACK = 150


# Modulate piece on lance
func set_color(color):
	$Modulation.modulate = color


# Deal DAMAGE to knight on hit (if not parried)
func _hit_knight(knight):
	._hit_knight(knight)
	var backwards = knight.global_position - knight_held_by.global_position
	var knockback = backwards.normalized() * KNOCKBACK
	if knight.parrying:
		_knock_off_knight(knight_held_by, -knockback)
	else:
		_damage_knight(knight, DAMAGE, knockback)


# Start a duel between the two players
func _hit_weapon(weapon):
	if weapon.can_duel:
		_duel_player(weapon.player_held_by)
