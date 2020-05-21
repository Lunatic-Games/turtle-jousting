extends Area2D


signal hit_fellow_turtle
signal picked_up_powerup


func _ready():
	pass


func _on_area_entered(area):
	if area.is_in_group("turtle") and area.get_parent() != get_parent():
		emit_signal("hit_fellow_turtle")
	if area.is_in_group("powerup"):
		emit_signal("picked_up_powerup", area)
		area.picked_up()
		
