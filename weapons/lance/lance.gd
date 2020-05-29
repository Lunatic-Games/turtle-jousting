extends "res://weapons/weapon.gd"


const DAMAGE = 20
const KNOCKBACK = 150


# Modulate piece on lance
func set_color(color):
	$Modulation.modulate = color


# Deal damage to knight on hit (if not parried)
func _hit_knight(knight):
	._hit_knight(knight)
	var backwards = knight.global_position - knight_held_by.global_position
	var knockback = backwards.normalized() * KNOCKBACK
	if knight.parrying:
		player_held_by.call_deferred("knock_knight_off", -knockback)
	else:
		knight.call_deferred("hit", DAMAGE, knockback)


# Start a duel between the two players
func _hit_weapon(weapon):
	player_held_by.call_deferred("duel", weapon.player_held_by)
