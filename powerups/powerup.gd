extends Area2D


signal picked_up


func _ready():
	pass


func picked_up():
	emit_signal("picked_up")
	call_deferred("queue_free")
