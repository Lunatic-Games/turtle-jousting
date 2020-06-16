extends "res://weapons/weapon.gd"


export (Curve) var damage_curve

const DAMAGE = 20
const KNOCKBACK = 150

remote var charge = 0  # Value between 0 and 1 for damage curve
var angle = 0


# Modulate piece on lance
func set_color(color):
	$Modulation.modulate = color


# Deal DAMAGE to knight on hit (if not parried)
func _hit_knight(knight):
	._hit_knight(knight)
	if (overlaps_area(knight.weapon_handle.weapon) 
			and knight.weapon_handle.weapon.can_joust):
		return
	var forwards = Vector2(cos(angle), sin(angle))
	var knockback = forwards.normalized() * KNOCKBACK
	if knight.parrying:
		_knock_off_knight(knight_held_by, -knockback)
	else:
		_damage_knight(knight, int(DAMAGE * damage_curve.interpolate(charge)),
			knockback)
		_knock_off_knight(knight, knockback)


# Start a duel between the two players
func _hit_weapon(weapon):
	._hit_weapon(weapon)
	if weapon.can_duel:
		_damage_knight(weapon.knight_held_by, 
			int(DAMAGE * damage_curve.interpolate(charge)))
		if charge >= weapon.charge:
			var forwards = Vector2(cos(angle), sin(angle))
			var knockback = forwards.normalized() * KNOCKBACK
			_knock_off_knight(weapon.knight_held_by, knockback)
		areas_hit.append(weapon.knight_held_by)


func set_charge(new_charge):
	charge = new_charge
	if get_tree().network_peer:
		rset("charge", charge)
