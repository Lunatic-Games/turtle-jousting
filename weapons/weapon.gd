extends Area2D


signal hit_knight
signal hit_weapon
signal hit_turtle

export (bool) var can_joust

var player_held_by
var knight_held_by


# Called when weapon first picked up
func set_player(player):
	player_held_by = player
	knight_held_by = player.get_node("Knight")


# Set modulation of weapon for player color
func set_color(_color):
	pass


# Emit signals based on what entered
func _on_area_entered(area):
	if !player_held_by:
		return

	if area.is_in_group("knight") and !player_held_by.is_a_parent_of(area):
		_hit_knight(area)
	elif area.is_in_group("weapon"):
		_hit_weapon(area)
	elif area.is_in_group("turtle") and !player_held_by.is_a_parent_of(area):
		_hit_turtle(area)


# Hit another knight
func _hit_knight(knight):
	emit_signal("hit_knight", knight)


# Hit another knight's weapon
func _hit_weapon(weapon):
	emit_signal("hit_weapon", weapon)


# Hit another turtle
func _hit_turtle(turtle):
	emit_signal("hit_turtle", turtle)
