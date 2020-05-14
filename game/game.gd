extends Node2D

const player_scene = preload("res://player/player.tscn")


func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass


func add_player(number, net_id, data = {}):
	var new_player = player_scene.instance()
	new_player.name = "Player" + str(number)
	new_player.load_data(data)
	new_player.set_network_master(net_id)
	$YSort.add_child(new_player)


func all_players_added():
	var players = get_tree().get_nodes_in_group("player")
	var num = len(players)
	var spawn_positions = get_node("SpawnPositions/" + str(num) + "Player")
	var i = 1
	for player in players:
		var spawn_node = spawn_positions.get_node("Player" + str(i))
		player.global_position = spawn_node.global_position
		if spawn_node.global_position.x > 1024 / 2:
			player.invert_start_direction()
		player.update_sprite_direction(Vector2(0, 0))
		i += 1
	
