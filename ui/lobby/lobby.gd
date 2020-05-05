extends Control

const DEFAULT_PORT = 32200

onready var player_container = get_node("HBoxContainer/GameContainer/" +  
	"VBoxContainer/PlayerContainer")


func _ready():
	var p1_label = player_container.get_node("PlayerSlot1/CenterContainer/Name")
	p1_label.text = "Player 1"
	
	var _err = get_tree().connect("network_peer_connected", self, "_new_connection")
	_err = get_tree().connect("network_peer_disconnected", self, "_disconnection")
	_err = get_tree().connect("connected_to_server", self, "_connected_ok")
	_err = get_tree().connect("connection_failed", self, "_connected_fail")
	_err = get_tree().connect("server_disconnected", self, "_server_disconnected")
	
# Open to multiplayer
func create_server():
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(DEFAULT_PORT, 4)
	if result == OK:
		print("Created server on port ", DEFAULT_PORT)
	else:
		print("Failed to create server on port ", DEFAULT_PORT)
	get_tree().network_peer = peer
	
# Attempt to join using ip
func connect_to_server():
	var peer = NetworkedMultiplayerENet.new()
	var ip = $CodeSection/HBoxContainer/CodeEditContainer/TextEdit.text
	var result = peer.create_client(ip, DEFAULT_PORT)
	if result == OK:
		print("Connected successfully to ", ip)
	else:
		print("Failed to connect to ", ip)
		return
	get_tree().network_peer = peer

# Keep track of other connections
var connections = []

# Players of this connection
var players = [1]

# Called (on client and server) when a peer connects
func _new_connection(id):
	rpc_id(id, "register_connection")

# Called when a peer disconnects
func _disconnection(id):
	connections.remove(connections.find(id))
	
# Called on client when connected
func _connected_ok():
	print("Connected okay")
	
# Called if kicked by server
func _server_disconnected():
	pass
	
# Called on client failure to connect
func _connected_fail():
	pass

# Register new connection
remote func register_connection():
	print("Registering connection")
	var id = get_tree().get_rpc_sender_id()
	connections.append(id)
