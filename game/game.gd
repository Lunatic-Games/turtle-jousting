extends Node2D

const player_scene = preload("res://player/player.tscn")
var player_spawn_x = 50
var player_spawn_y = 50

func _ready():
	pass

func add_player(number, net_id, data = {}):
	var new_player = player_scene.instance()
	new_player.name = "Player" + str(number)
	new_player.load_data(data)
	new_player.set_network_master(net_id)
	new_player.position = Vector2(player_spawn_x, player_spawn_y)
	player_spawn_x += 50
	add_child(new_player)
