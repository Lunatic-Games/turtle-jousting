extends Area2D


signal hit_fellow_turtle
signal picked_up_powerup
signal picked_up_knight


func _ready():
	pass


func _on_area_entered(area):
	if area.is_in_group("turtle") and area.get_parent() != get_parent():
		emit_signal("hit_fellow_turtle")
	if area.is_in_group("powerup"):
		emit_signal("picked_up_powerup", area)
		area.pick_up()
	if area.is_in_group("knight") and area.in_water:
		if area.number == get_parent().number:
			emit_signal("picked_up_knight", area)
		
