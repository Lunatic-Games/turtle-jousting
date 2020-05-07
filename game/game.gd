extends Node2D

const player_scene = preload("res://player/player.tscn")

func _ready():
	pass

func add_player(number, net_id, data = {}):
	var new_player = player_scene.instance()
	new_player.name = "Player" + str(number)
	new_player.load_data(data)
	new_player.set_network_master(net_id)
	add_child(new_player)
