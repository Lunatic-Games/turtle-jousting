extends Control


const arena_scene = preload("res://arena/arena.tscn")

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

# Has useful network functions
var network_handler = preload("res://ui/lobby/networking.gd").new()

# Stores data for servers and clients
var server
var client

# Allows creation of server without stopping processing
var server_creation_thread


# Setup
func _ready():
	var _err = get_tree().connect("network_peer_connected", self, "_new_connection")
	_err = get_tree().connect("network_peer_disconnected", self, "_disconnection")
	_err = get_tree().connect("connected_to_server", self, "_connected_ok")
	_err = get_tree().connect("connection_failed", self, "_connected_fail")
	_err = get_tree().connect("server_disconnected", self, "_server_disconnected")
	$VisorTransition.lift_up()


# Check for keyboard popup and register new devices
func _input(event):
	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"
	
	if event.is_action("ui_accept") and event.pressed:
		if (event is InputEventJoypadButton and 
				online_container.get_node("CodeEditContainer/LineEdit").has_focus()):
			var line_edit = online_container.get_node("CodeEditContainer/LineEdit")
			$KeyboardPopup.display(line_edit)
			get_tree().set_input_as_handled()
			return
		if (event is InputEventJoypadButton and 
				local_container.get_node("CodeEditContainer/LineEdit").has_focus()):
			var line_edit = local_container.get_node("CodeEditContainer/LineEdit")
			$KeyboardPopup.display(line_edit)
			get_tree().set_input_as_handled()
			return

	elif event.is_action("ui_start") and event.pressed:
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
		get_tree().set_input_as_handled()

	elif event.is_action("ui_cancel") and event.pressed:
		_on_BackButton_pressed()


# Start server creation on new thread
func _on_OpenMultiplayerButton_pressed():
	if server_creation_thread and server_creation_thread.is_active():
		print("waiting for thread")
		return
	$NetworkMessagePopup.show_creating_server()
	button_container.get_node("OpenMultiplayerButton").release_focus()
	server_creation_thread = Thread.new()
	server_creation_thread.start(self, "_create_server")


# Open to multiplayer and update UI
func _create_server(_userdata):
	server = network_handler.create_server()
	if !server:
		print("Failed to create server")
		$NetworkMessagePopup.server_creation_failed()
		return
	get_tree().network_peer = server.peer
	server_creation_thread.call_deferred("wait_to_finish")
	call_deferred("_server_created", server.local_code, server.remote_code)


# Set host UI
func _server_created(local_code, remote_code):
	if remote_code:
		online_container.get_node("Code").text = remote_code
	else:
		online_container.get_node("Code").text = "Unavailable"
		
	if local_code:
		local_container.get_node("Code").text = local_code
	else:
		local_container.get_node("Code").text = "Unavailable"
	
	toggle_ui_visibility("multiplayer_ui", true)
	toggle_ui_visibility("host_ui", true)
	button_container.get_node("OpenMultiplayerButton").visible = false
	button_container.get_node("CloseMultiplayerButton").grab_focus()
	toggle_ui_visibility("disconnected_ui", false)
	$NetworkMessagePopup.hide()


# Close server and update UI
func _close_server():
	print("Closing server")
	get_tree().network_peer = null
	reset_to_local()
	
	button_container.get_node("OpenMultiplayerButton").visible = true
	button_container.get_node("OpenMultiplayerButton").grab_focus()
	button_container.get_node("CloseMultiplayerButton").visible = false
	toggle_ui_visibility("disconnected_ui", true)
	toggle_ui_visibility("multiplayer_ui", false)


# Attempt to join using ip
func _connect_to_server(code):
	$NetworkMessagePopup.show_connecting()
	online_container.get_node("JoinContainer/Button").release_focus()
	local_container.get_node("JoinContainer/Button").release_focus()
	if !network_handler.is_valid_code(code):
		print("Invalid code")
		$NetworkMessagePopup.invalid_code()
		return
	
	client = network_handler.connect_to_server_with_code(code)
	if !client:
		$NetworkMessagePopup.connection_failed()
		return

	get_tree().network_peer = client.peer
	$ConnectionTimer.start()


# When online join pressed
func _connect_online():
	var code = online_container.get_node("CodeEditContainer/LineEdit").text
	_connect_to_server(code)


# When local join pressed
func _connect_local():
	var code = local_container.get_node("CodeEditContainer/LineEdit").text
	_connect_to_server(code)
	

# Tell the new client connection to add itself
func _new_connection(id):
	if is_network_master():
		rpc_id(id, "join", connections, server.remote_code, server.local_code)


# Remove associated player slots on client disconnect
func _disconnection(id):
	if !connections.has(id):
		return
	for player in connections[id].keys():
		get_player_slot(player).reset()
	connections.erase(id)


# Called on client when connected
func _connected_ok():
	$ConnectionTimer.stop()
	$NetworkMessagePopup.hide()


# Called if kicked by server
func _server_disconnected():
	print("Disconnected by server")
	_disconnect()


# Called on client failure to connect
func _connected_fail():
	print("Failed to connect")
	$NetworkMessagePopup.hide()
	$ConnectTimeout.stop()


# Add players and register connection
remote func join(existing_connections, remote_code, local_code):
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
			return
		else:
			new_local_players[pos] = local_players[player]
			player_data[pos] = get_player_slot(player).get_player_data()
			connections[net_id].append(pos)
		
	_joined_lobby(remote_code, local_code)
	local_players = new_local_players
	load_existing_connections()
	rpc("update_player_list", local_players)
	for player in local_players.keys():
		get_player_slot(player).load_player(player, player_data[player])
		get_player_slot(player).set_network_master(net_id)
		get_player_slot(player).send_data()
	rpc("new_connection")

# Update connection player numbers and player slots
remote func update_player_list(players):
	var sender_id = get_tree().get_rpc_sender_id()
	
	var player_data = {}
	if connections.has(sender_id):
		for player in connections[sender_id]:
			player_data[player] = get_player_slot(player).get_player_data()
			get_player_slot(player).reset()

	connections[sender_id] = players
	for player in connections[sender_id]:
		get_player_slot(player).load_player(player, player_data.get(player, {}))
		get_player_slot(player).set_network_master(sender_id)
		

# Send existing data to the new connection
remote func new_connection():
	for player in local_players.keys():
		get_player_slot(player).send_data()


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
func _joined_lobby(remote_code, local_code):
	toggle_ui_visibility("client_ui", true)
	toggle_ui_visibility("host_ui", false)
	toggle_ui_visibility("disconnected_ui", false)
	toggle_ui_visibility("multiplayer_ui", true)
	button_container.get_node("LeaveLobbyButton").grab_focus()
	online_container.get_node("Code").text = remote_code
	local_container.get_node("Code").text = local_code


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
	if server:
		server.close()
	if client:
		client.close()
	get_tree().network_peer = null
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
	$VisorTransition.bring_down(self, "_call_start")


func _call_start():
	if get_tree().network_peer:
		rpc("start")
	else:
		start()


remotesync func start():
	get_tree().paused = true
	if get_tree().network_peer and is_network_master():
		get_tree().refuse_new_network_connections = true

	var new_arena = arena_scene.instance()
	for connection in connections:
		for player in connections[connection]:
			var data = {}
			if player in local_players.keys():
				data = get_player_slot(player).get_player_data()
			new_arena.add_player(player, connection, data)
	get_tree().get_root().add_child(new_arena)
	new_arena.all_players_added()
	visible = false
	set_process(false)
	set_process_input(false)


func return_to():
	if get_tree().network_peer and is_network_master():
		get_tree().refuse_new_network_connections = false
	$VisorTransition.lift_up()
	visible = true
	set_process(true)
	set_process_input(true)


func _on_BackButton_pressed():
	$VisorTransition.bring_down(self, "_go_back")
	

# Exit game (this will eventually lead back to main menu)
func _go_back():
	var _err= get_tree().change_scene("res://ui/main/main_menu.tscn")


# Clear used port when exiting
func _exit_tree():
	if server_creation_thread and server_creation_thread.is_active():
		server_creation_thread.wait_to_finish()
	if server:
		server.close()
	if client:
		client.close()
	if get_tree().network_peer:
		get_tree().network_peer = null


func _on_ConnectionTimer_timeout():
	get_tree().network_peer = null
	$NetworkMessagePopup.connection_failed()


func _on_VisorTransition_lifted_up():
	if button_container.get_node("OpenMultiplayerButton").visible:
		button_container.get_node("OpenMultiplayerButton").grab_focus()
	else:
		button_container.get_node("CloseMultiplayerButton").grab_focus()


func _on_Popup_about_to_show():
	set_process_input(false)


func _on_Popup_hide():
	set_process_input(true)
