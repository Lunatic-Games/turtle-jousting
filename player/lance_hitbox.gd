extends Area2D


signal hit_something


func _ready():
	pass


func _on_area_entered(area):
	if area.is_in_group("knight") and area.get_parent() != get_parent():
		emit_signal("hit_something")
		var player = area.get_parent()
		if player.parrying:
			print("ITS A TRAP")
		else:
			print("Rekt")
	elif area.is_in_group("weapon"):
		emit_signal("hit_something")
