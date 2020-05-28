extends "res://weapons/weapon.gd"


const DAMAGE = 10
const KNOCKBACK = 150


# Modulate piece on lance
func set_color(color):
	$Modulation.modulate = color


# Deal damage to knight on hit (if not parried)
func _hit_knight(knight):
	._hit_knight(knight)
	if knight.parrying:
		var backwards = knight_held_by.global_position - knight.global_position
		var knockback = backwards.normalized() * KNOCKBACK
		player_held_by.call_deferred("knock_knight_off", knockback)
	else:
		knight.call_deferred("hit", DAMAGE)


# Start a duel between the two players
func _hit_weapon(weapon):
	player_held_by.call_deferred("duel", weapon.player_held_by)
