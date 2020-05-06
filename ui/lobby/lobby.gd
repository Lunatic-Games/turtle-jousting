extends Control

const DEFAULT_PORT = 32200

onready var player_container = get_node("HBoxContainer/GameContainer/" +  
	"VBoxContainer/PlayerContainer")

# Keeps track of connections, connection_id : player_array
var connections = {}

# Keeps track of local players, player_num : device_id
var local_players = {}

# Setup
func _ready():
	player_container.get_node("PlayerSlot1").player_loaded(1)
	player_container.get_node("PlayerSlot2").player_loaded(2)
	local_players[1] = 0
	local_players[2] = 1
	
	var _err = get_tree().connect("network_peer_connected", self, "_new_connection")
	_err = get_tree().connect("network_peer_disconnected", self, "_disconnection")
	_err = get_tree().connect("connected_to_server", self, "_connected_ok")
	_err = get_tree().connect("connection_failed", self, "_connected_fail")
	_err = get_tree().connect("server_disconnected", self, "_server_disconnected")
	
# Open to multiplayer and update UI
func _create_server():
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(DEFAULT_PORT, 4)
	if result == OK:
		print("Created server on port ", DEFAULT_PORT)
	else:
		print("Failed to create server on port ", DEFAULT_PORT)
		return
	get_tree().network_peer = peer
	connections[1] = local_players.keys()
	
	#$CodeSection/HBoxContainer/Code.text = IP.get_local_addresses()[0]
	toggle_ui_visibility("multiplayer_ui", true)
	toggle_ui_visibility("host_ui", true)
	$HBoxContainer/GameContainer/VBoxContainer/OpenMultiplayerButton.visible = false
	toggle_ui_visibility("disconnected_ui", false)
		
# Close server and update UI
func _close_server():
	get_tree().network_peer = null
	connections[1] = local_players.keys()
	reset_to_local()
	
	$HBoxContainer/GameContainer/VBoxContainer/OpenMultiplayerButton.visible = true
	$HBoxContainer/GameContainer/VBoxContainer/CloseMultiplayerButton.visible = false
	toggle_ui_visibility("disconnected_ui", true)
	toggle_ui_visibility("multiplayer_ui", false)
	
# Attempt to join using ip
func _connect_to_server():
	var ip = $CodeSection/HBoxContainer/CodeEditContainer/TextEdit.text
	if ip == "":
		return
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(ip, DEFAULT_PORT)
	if result == OK:
		print("Client succesfully created")
	else:
		print("Failed to connect to ", ip)
		return
	get_tree().network_peer = peer

# Called the new client connection to register itself
func _new_connection(id):
	if is_network_master():
		rpc_id(id, "register_connection", connections)

# Remove associated player slots on client disconnect
func _disconnection(id):
	if !connections.has(id):
		return
	for player in connections[id]:
		get_player_slot(player).reset()
	connections.erase(id)
	
# Called on client when connected
func _connected_ok():
	toggle_ui_visibility("client_ui", true)
	toggle_ui_visibility("host_ui", false)
	toggle_ui_visibility("disconnected_ui", false)
	toggle_ui_visibility("multiplayer_ui", true)
	
# Called if kicked by server
func _server_disconnected():
	print("Disconnected by server")
	reset_to_local()
	
# Called on client failure to connect
func _connected_fail():
	print("Connection failed")

# Add players and register connection
remote func register_connection(existing_connections):
	var new_local_players = {}
	var new_player_list = []
	for key in local_players.keys():
		for j in range(1, 5):
			if !new_local_players.has(j) and !is_slot_taken(j, existing_connections):
				new_player_list.append(j)
				new_local_players[j] = local_players[key]
				break
	if len(new_player_list) < len(local_players.keys()):
		print("Not enough room to join")
		get_tree().network_peer = null
		return

	local_players = new_local_players
	rpc("update_players", new_player_list)
		
# Update connection player numbers and player slots
remotesync func update_players(new_player_list):
	var sender_id = get_tree().get_rpc_sender_id()
	if connections.has(sender_id):
		for player in connections[sender_id]:
			get_player_slot(player).reset()
	connections[sender_id] = new_player_list
	for player in connections[sender_id]:
		get_player_slot(player).player_loaded(player)
	
# Get associated player slot
func get_player_slot(num):
	return player_container.get_child(num - 1)
	
# Disconnect self from server
func _disconnect():
	get_tree().network_peer = null
	reset_to_local()
	toggle_ui_visibility("multiplayer_ui", false)
	toggle_ui_visibility("host_ui", true)
	$HBoxContainer/GameContainer/VBoxContainer/CloseMultiplayerButton.visible = false
	toggle_ui_visibility("client_ui", false)
	toggle_ui_visibility("disconnected_ui", true)

# Determine if player number is available
func is_slot_taken(i, existing_connections):
	for key in existing_connections.keys():
		if existing_connections[key].has(i):
			return true
	return false
	
# Toggle the visibility of all ui in a group
func toggle_ui_visibility(group_name, visibility):
	for element in get_tree().get_nodes_in_group(group_name):
		element.visible = visibility
		
func reset_to_local():
	for i in range(1, 5):
		get_player_slot(i).reset()
		
	var new_local_players = {}
	var i = 1
	for key in local_players.keys():
		new_local_players[i] = local_players[key]
		get_player_slot(i).player_loaded(i)
		i += 1

# Exit game (this will eventually lead back to main menu)
func _exit():
	get_tree().quit()
