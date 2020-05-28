extends "res://weapons/weapon.gd"


const DAMAGE = 10


# Modulate piece on lance
func set_color(color):
	$Modulation.modulate = color


# Deal damage to knight on hit (if not parried)
func _hit_knight(knight):
	._hit_knight(knight)
	if knight.parrying:
		var backwards = knight_held_by.global_position - knight.global_position
		backwards = backwards.normalized()
		player_held_by.knock_knight_off(backwards)
	else:
		knight.hit(DAMAGE)


# Start a duel between the two players
func _hit_weapon(weapon):
	player_held_by.duel(weapon.player_held_by)
