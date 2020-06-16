extends "res://weapons/throwable.gd"


const DAMAGE = 20
const HEAL = 20

func _hit_knight(knight):
	_damage_knight(knight, DAMAGE)
	_heal_knight(knight_held_by, HEAL)
	_q_free()
