extends "res://weapons/throwable.gd"


const DAMAGE = 20
const HEAL = 20

func _hit_knight(knight):
	knight.call_deferred("hit", DAMAGE)
	knight_held_by.call_deferred("heal", HEAL)
	queue_free()
