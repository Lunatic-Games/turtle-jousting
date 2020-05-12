extends Node


const DEFAULT_PORT = 9000
const BASE_36_DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']

class Server:
	var peer
	var upnp
	var remote_ip
	var remote_code
	var local_ip
	var local_code
	
	func close():
		print("Deleting port mapping")
		upnp.delete_port_mapping(DEFAULT_PORT)
		peer.close_connection()
		
	
class Client:
	var peer
	
	func close():
		peer.close_connection()


# Creates a server on DEFAULT_PORT and returns the upnp instance
func create_server():
	var server = Server.new()
	
	server.upnp = UPNP.new()
	server.upnp.discover(2000, 2, "InternetGatewayDevice")
	server.upnp.add_port_mapping(DEFAULT_PORT)
	
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(DEFAULT_PORT, 4)
	if result == OK:
		print("Created server on port ", DEFAULT_PORT)
	else:
		print("Failed to create server on port ", DEFAULT_PORT)
		return null

	server.peer = peer
	server.remote_ip = server.upnp.query_external_address()
	if server.remote_ip:
		server.remote_code = _generate_code(server.remote_ip)
	server.local_ip = _get_local_ip()
	if server.local_ip:
		server.local_code = _generate_code(server.local_ip)
	
	return server
	
func connect_to_server(ip):
	var client = Client.new()
	
	client.peer = NetworkedMultiplayerENet.new()
	var result = client.peer.create_client(ip, DEFAULT_PORT)
	if result != OK:
		
		print("Failed to create client")
		return null

	return client
	
func connect_to_server_with_code(code):
	return connect_to_server(_decode_code(code))


func is_valid_code(code):
	var reg_ex = RegEx.new()
	reg_ex.compile("^([a-zA-Z0-9]+)$")
	return reg_ex.search(code)


# Goes through local addresses to find a valid ipv4 address
func _get_local_ip():
	var local_ip = "Unavailable"
	var local_addresses = IP.get_local_addresses()
	var ipv4_pattern = RegEx.new()
	ipv4_pattern.compile('^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$')
	for address in local_addresses:
		var result = ipv4_pattern.search(address)
		if result and result.get_string() != "127.0.0.1":
			local_ip = result.get_string()
	return local_ip
	
# Generate a base 36 code from a given ip
func _generate_code(ip):
	var sections = ip.split('.')
	ip = ""
	for i in range(len(sections)):
		ip += sections[i].pad_zeros(3)
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
	result = str(result).pad_zeros(12)
	for i in range(len(result) - 3, 2, -3):
		result = result.insert(i, '.')
	return result
