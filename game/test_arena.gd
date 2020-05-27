extends Node2D


func _ready():
	$Player.load_data({"device_id": 0, "color": Color.blueviolet})
	$Player.set_process_input(false)
	$Player.set_process_input(true)
	$Player2.load_data({"device_id": "keyboard", "color": Color.springgreen})
	$Player2.set_process_input(false)
	$Player2.set_process_input(true)
	var p3 = $Player2.duplicate()
	p3.position += Vector2(200, 200)
	add_child(p3)
