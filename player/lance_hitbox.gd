extends Area2D


signal hit_weapon
signal hit_player
signal parried


func _ready():
	pass


func _on_area_entered(area):
	if area.is_in_group("knight") and area != get_parent():
		if area.parrying:
			var backwards = global_position - area.global_position
			emit_signal("parried", backwards.normalized())
		else:
			area.hit(1)
	elif area.is_in_group("weapon"):
		emit_signal("hit_weapon")
