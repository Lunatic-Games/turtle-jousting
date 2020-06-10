extends Node2D


func _ready():
	randomize()
	$Player.load_data({"device_id": 1, "number": 1, "color": Color.blueviolet})
	$Player.set_process_input(true)
	$Player2.load_data({"device_id": "keyboard", "number": 2, "color": Color.springgreen})
	$Player2.set_process_input(true)
	$Player2.invert_start_direction()
