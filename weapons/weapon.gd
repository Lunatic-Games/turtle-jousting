extends Area2D


signal hit_knight
signal hit_weapon
signal hit_turtle

export (bool) var can_joust
export (bool) var can_duel
export (bool) var can_sweep

const DEFAULT_KNOCKBACK = 200

var damage_mod = 1
var player_held_by
var knight_held_by
var areas_hit = []


# Called when weapon first picked up
func pick_up(player):
	player_held_by = player
	if player.has_node("Knight"):
		knight_held_by = player.get_node("Knight")
	visible = true
	$CollisionShape2D.disabled = true


# Remove all areas hit, useful for when starting a new attack
func reset_areas_hit():
	areas_hit.clear()


# Set modulation of weapon for player color
func set_color(_color):
	pass


# Emit signals based on what entered
func _on_area_entered(area):
	if !player_held_by or areas_hit.has(area):
		return

	if area.is_in_group("knight") and area != knight_held_by:
		_hit_knight(area)
	elif area.is_in_group("weapon"):
		_hit_weapon(area)
	elif area.is_in_group("turtle_hitbox") and !player_held_by.is_a_parent_of(area):
		_hit_turtle(area)


# Hit another knight
func _hit_knight(knight):
	emit_signal("hit_knight", knight)
	areas_hit.append(knight)


# Hit another knight's weapon
func _hit_weapon(weapon):
	emit_signal("hit_weapon", weapon)
	areas_hit.append(weapon)


# Hit another turtle
func _hit_turtle(turtle):
	emit_signal("hit_turtle", turtle)
	areas_hit.append(turtle)


# Hide and disable
func put_away():
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)


# Damage knight by given damage and apply damage mod
func _damage_knight(knight, damage, knockback=Vector2(0, 0)):
	knight.call_deferred("hit", damage*damage_mod, knockback)


# Knock knight off of player with given knockback
func _knock_off_knight(knight, knockback):
	var player = knight.get_parent()
	if !player:
		return
	player.call_deferred("knock_knight_off", knockback)


# Tell weapon to unequp this weapon
func _unequip():
	get_parent().call_deferred("unequip_held_weapon")


# Duel another player
func _duel_player(player):
	player_held_by.call_deferred("duel", player)


# A single sweep attack, used for some weapons
func sweep():
	pass


# Called at end of sweep animation
func sweep_done():
	pass
