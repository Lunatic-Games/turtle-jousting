extends Control

const DEFAULT_PORT = 32200

onready var player_container = get_node("HBoxContainer/GameContainer/" +  
	"VBoxContainer/PlayerContainer")

# Keeps track of connections, connection_id : player_array
var connections = {}

# Keeps track of local players, player_num : device_id
var local_players = {}

func _ready():
	player_container.get_node("PlayerSlot1").player_loaded(1)
	local_players[1] = 0
	
	var _err = get_tree().connect("network_peer_connected", self, "_new_connection")
	_err = get_tree().connect("network_peer_disconnected", self, "_disconnection")
	_err = get_tree().connect("connected_to_server", self, "_connected_ok")
	_err = get_tree().connect("connection_failed", self, "_connected_fail")
	_err = get_tree().connect("server_disconnected", self, "_server_disconnected")
	
# Open to multiplayer
func _create_server():
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(DEFAULT_PORT, 4)
	if result == OK:
		print("Created server on port ", DEFAULT_PORT)
	else:
		print("Failed to create server on port ", DEFAULT_PORT)
	get_tree().network_peer = peer
	
# Attempt to join using ip
func _connect_to_server():
	var ip = $CodeSection/HBoxContainer/CodeEditContainer/TextEdit.text
	if ip == "":
		return
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(ip, DEFAULT_PORT)
	if result == OK:
		print("Connected successfully to ", ip)
	else:
		print("Failed to connect to ", ip)
		return
	get_tree().network_peer = peer
	set_network_master(1)

# Called (on client and server) when a peer connects
func _new_connection(id):
	rpc_id(id, "register_connection", connections)

# Called when a peer disconnects
func _disconnection(id):
	connections.erase(id)
	
# Called on client when connected
func _connected_ok():
	pass
	
# Called if kicked by server
func _server_disconnected():
	pass
	
# Called on client failure to connect
func _connected_fail():
	pass

# Register new connection
remote func register_connection(existing_connections):
	print("Registering connection")
	var sender_id = get_tree().get_rpc_sender_id()
	
	if sender_id == 1:
		var new_local_players = {}
		var new_player_list = []
		for key in local_players.keys():
			for j in range(1, 5):
				if !new_local_players.has(j) and !existing_connections.has(j):
					new_player_list.append(j)
					new_local_players[j] = local_players[key]
					break
		local_players = new_local_players
		print("Local players: ", local_players)
		rpc("update_players", new_player_list)
		
	
remote func update_players(new_player_list):
	var sender_id = get_tree().get_rpc_sender_id()
	for player in connections[sender_id]:
		get_player_slot(player).reset()
	connections[sender_id] = new_player_list
	for player in connections:
		get_player_slot(player).player_loaded(player)
	
func get_player_slot(num):
	return player_container.get_child(num + 1)
	
# Exit game (this will eventually lead back to main menu)
func _exit():
	get_tree().quit()
