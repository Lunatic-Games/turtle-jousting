extends Control

const DEFAULT_PORT = 32000
const BASE_36_DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
const game_scene = preload("res://game/game.tscn")

onready var player_container = get_node("LobbySections/GameContainer/" +  
	"VBoxContainer/PlayerContainer")
onready var button_container = get_node("LobbySections/GameContainer/" +
	"VBoxContainer")
onready var online_container = get_node("ConnectionSection/VBoxContainer/" + 
	"OnlineContainer")
onready var local_container = get_node("ConnectionSection/VBoxContainer/" + 
	"LocalContainer")

# Keeps track of multiplayer connections, connection_id : player_list
var connections = {}

# Keeps track of local players, player_number : device_id
var local_players = {}

var valid_code_regex = RegEx.new()

# Setup
func _ready():
	var _err = get_tree().connect("network_peer_connected", self, "_new_connection")
	_err = get_tree().connect("network_peer_disconnected", self, "_disconnection")
	_err = get_tree().connect("connected_to_server", self, "_connected_ok")
	_err = get_tree().connect("connection_failed", self, "_connected_fail")
	_err = get_tree().connect("server_disconnected", self, "_server_disconnected")
	valid_code_regex.compile("^([a-zA-Z0-9]+)$")


# Register new devices
func _input(event):
	if event.is_action("ui_accept") and event.pressed:
		var device = event.device
		if event is InputEventKey or event is InputEventMouse:
			device = "keyboard"
		if device in local_players.values():
			return

		var pos = get_next_open_position()
		if pos == -1:
			print("Lobby full")
			return
		
		local_players[pos] = device
		if get_tree().network_peer:
			rpc("update_player_list", local_players)
			var net_id = get_tree().get_network_unique_id()
			get_player_slot(pos).set_network_master(net_id)
			connections[net_id] = local_players.keys()
		else:
			connections[1] = local_players.keys()

		get_player_slot(pos).load_player(pos, {"device_id" : device})


# Open to multiplayer and update UI
func _create_server():
	var upnp = UPNP.new()
	upnp.discover(2000, 2, "InternetGatewayDevice")
	upnp.add_port_mapping(DEFAULT_PORT)
	
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(DEFAULT_PORT, 4)
	if result == OK:
		print("Created server on port ", DEFAULT_PORT)
	else:
		print("Failed to create server on port ", DEFAULT_PORT)
		return
	get_tree().network_peer = peer
	
	var online_ip = upnp.query_external_address()
	if online_ip == "":
		online_container.get_node("Code").text = "Unavailable"
	else:
		online_container.get_node("Code").text = _generate_code(online_ip)
		
	var local_ip = get_local_ip()
	if local_ip == "":
		local_container.get_node("Code").text = "Unavailable"
	else:
		local_container.get_node("Code").text = _generate_code(local_ip)
	
	
	toggle_ui_visibility("multiplayer_ui", true)
	toggle_ui_visibility("host_ui", true)
	button_container.get_node("OpenMultiplayerButton").visible = false
	toggle_ui_visibility("disconnected_ui", false)


# Close server and update UI
func _close_server():
	get_tree().network_peer = null
	reset_to_local()
	
	button_container.get_node("OpenMultiplayerButton").visible = true
	button_container.get_node("CloseMultiplayerButton").visible = false
	toggle_ui_visibility("disconnected_ui", true)
	toggle_ui_visibility("multiplayer_ui", false)


# Attempt to join using ip
func _connect_to_server(ip):
	print("Attempting to connect to ip ", ip)
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(ip, DEFAULT_PORT)
	if result == OK:
		print("Client succesfully created")
	else:
		print("Failed to create client")
		return
	get_tree().network_peer = peer


func _connect_online():
	var code = online_container.get_node("CodeEditContainer/LineEdit").text
	if !valid_code_regex.search(code):
		print("Invalid code")
		return
	_connect_to_server(_decode_code(code))
	
func _connect_local():
	var code = local_container.get_node("CodeEditContainer/LineEdit").text
	if !valid_code_regex.search(code):
		print("Invalid code")
		return
	_connect_to_server(_decode_code(code))
	

# Tell the new client connection to add itself
func _new_connection(id):
	if is_network_master():
		rpc_id(id, "join", connections)


# Remove associated player slots on client disconnect
func _disconnection(id):
	if !connections.has(id):
		return
	for player in connections[id].keys():
		get_player_slot(player).reset()
	connections.erase(id)


# Called on client when connected
func _connected_ok():
	pass


# Called if kicked by server
func _server_disconnected():
	print("Disconnected by server")
	_disconnect()


# Called on client failure to connect
func _connected_fail():
	print("Connection failed")


# Add players and register connection
remote func join(existing_connections):
	connections = existing_connections
	var net_id = get_tree().get_network_unique_id()
	connections[net_id] = []
	var new_local_players = {}
	var player_data = {}
	
	for player in local_players.keys():
		var pos = get_next_open_position()
		if pos == -1:
			connections.clear()
			connections[1] = local_players.keys()
			get_tree().set_deferred("network_peer", null)
			print("Connections: ", connections)
			return
		else:
			new_local_players[pos] = local_players[player]
			player_data[pos] = get_player_slot(player).get_player_data()
			connections[net_id].append(pos)
		
	_joined_lobby()
	local_players = new_local_players
	load_existing_connections()
	rpc("update_player_list", local_players)
	for player in local_players.keys():
		get_player_slot(player).load_player(player, player_data[player])
		get_player_slot(player).set_network_master(net_id)


# Update connection player numbers and player slots
remote func update_player_list(players):
	var sender_id = get_tree().get_rpc_sender_id()
	
	if connections.has(sender_id):
		for player in connections[sender_id]:
			get_player_slot(player).reset()

	connections[sender_id] = players
	for player in connections[sender_id]:
		get_player_slot(player).load_player(player)
		get_player_slot(player).set_network_master(sender_id)


# Load players from connections that existed before joining
func load_existing_connections():
	var net_id = get_tree().get_network_unique_id()
	
	for connection in connections.keys():
		if connection == net_id:
			continue
		for player in connections[connection]:
			get_player_slot(player).load_player(player)
			get_player_slot(player).set_network_master(connection)


# Get associated player slot
func get_player_slot(num):
	return player_container.get_child(num - 1)


# Update UI for being a client
func _joined_lobby():
	toggle_ui_visibility("client_ui", true)
	toggle_ui_visibility("host_ui", false)
	toggle_ui_visibility("disconnected_ui", false)
	toggle_ui_visibility("multiplayer_ui", true)


# Disconnect self from server
func _disconnect():
	reset_to_local()
	get_tree().set_deferred("network_peer", null)
	toggle_ui_visibility("multiplayer_ui", false)
	toggle_ui_visibility("host_ui", true)
	button_container.get_node("CloseMultiplayerButton").visible = false
	toggle_ui_visibility("client_ui", false)
	toggle_ui_visibility("disconnected_ui", true)


# Reset the player slots to be only local players
func reset_to_local():
	connections.clear()
	connections[1] = []
	var old_local_players = local_players.duplicate()
	var player_data = {}
	local_players = {}
	
	for key in old_local_players.keys():
		var pos = get_next_open_position()
		local_players[pos] = old_local_players[key]
		player_data[pos] = get_player_slot(key).get_player_data()
		connections[1].append(pos)
		
	for i in range(1, 5):
		if player_data.has(i):
			get_player_slot(i).load_player(i, player_data[i])
		else:
			get_player_slot(i).reset()
		get_player_slot(i).set_network_master(1)


# Determine next available player number, returns -1 if none available
func get_next_open_position():
	for i in range(1, 5):
		if slot_is_open(i):
			return i
	return -1


# Determine if player number is available
func slot_is_open(i):
	for connection in connections:
		if connections[connection].has(i):
			return false
	return true


# Toggle the visibility of all ui in a group
func toggle_ui_visibility(group_name, visibility):
	for element in get_tree().get_nodes_in_group(group_name):
		element.visible = visibility


func _on_StartButton_pressed():
	if get_tree().network_peer:
		rpc("start")
	else:
		start()


remotesync func start():
	if get_tree().network_peer and is_network_master():
		get_tree().refuse_new_network_connections = true

	var new_game = game_scene.instance()
	for connection in connections:
		for player in connections[connection]:
			var data = {}
			if player in local_players.keys():
				data = get_player_slot(player).get_player_data()
			new_game.add_player(player, connection, data)
	get_tree().get_root().add_child(new_game)
	queue_free()


# Exit game (this will eventually lead back to main menu)
func _exit():
	get_tree().quit()


# Generate a base 36 code from a given ip
func _generate_code(ip):
	print("Generating code for ip ", ip)
	var sections = ip.split('.')
	ip = ""
	for i in range(len(sections)):
		for _k in range(len(sections[i]), 3):
			sections[i] = "0" + sections[i]
		ip += sections[i]
		if i < len(sections) - 1:
			ip += "."
	ip = ip.replace('.', '')
	ip = int(ip)
	
	var digits = []
	while true:
		var remainder = ip % 36
		digits.push_front(remainder)
		ip = int(floor(ip / 36))
		if ip < 36:
			digits.push_front(ip)
			break
	var code = ""
	for digit in digits:
		code = code + BASE_36_DIGITS[digit]
	return code


# Generate an ip from a base 36 code
func _decode_code(code):
	code = code.to_lower()
	var digits = []
	for c in code:
		digits.push_front(int(BASE_36_DIGITS.find(c)))
	var multiplier = 1
	var result = 0
	for digit in digits:
		result += digit * multiplier
		multiplier *= 36
	result = str(result)
	for _i in range(12 - len(result)):
		result = "0" + result
	for i in range(len(result) - 3, 2, -3):
		result = result.insert(i, '.')
	return result


# Goes through local addresses to find a valid ipv4 address
func get_local_ip():
	var local_ip = "Unavailable"
	var local_addresses = IP.get_local_addresses()
	var ipv4_pattern = RegEx.new()
	ipv4_pattern.compile('^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$')
	for address in local_addresses:
		var result = ipv4_pattern.search(address)
		if result and result.get_string() != "127.0.0.1":
			local_ip = result.get_string()
	return local_ip

