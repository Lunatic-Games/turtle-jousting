extends Popup


enum NetworkType {SERVER, CLIENT}
const CONNECTING_MESSAGE = "Connecting"
const CREATING_SERVER_MESSAGE = "Creating server"
const MAX_DOTS = 3
var differing_message = "Differing versions\nServer: v%s\nClient: v%s"
var dots = 1
var net_type


func show_connecting():
	popup()
	$DotTimer.start()
	$ConnectingMessage.text = CONNECTING_MESSAGE + " ."
	$ConnectingMessage.visible = true
	net_type = NetworkType.CLIENT


func show_creating_server():
	popup()
	$DotTimer.start()
	$CreatingServerMessage.text = CREATING_SERVER_MESSAGE + " ."
	$CreatingServerMessage.visible = true
	net_type = NetworkType.SERVER


func show_not_everyone_ready():
	popup()
	$NotEveryoneReadyMessage.visible = true
	$FailureTimer.start()


func show_not_enough_players():
	popup()
	$NotEnoughPlayersMessage.visible = true
	$FailureTimer.start()


func show_differing_versions(var s_version, var c_version):
	popup()
	$FailureTimer.wait_time = 2.0
	$DifferingVersionMessage.text = differing_message % [s_version, c_version]
	$DifferingVersionMessage.visible = true
	$FailureTimer.start()

func hide():
	$FailureTimer.stop()
	$FailureTimer.wait_time = 1.0
	$DotTimer.stop()
	$ConnectingMessage.visible = false
	$CreatingServerMessage.visible = false
	$ConnectionFailedMessage.visible = false
	$InvalidCodeMessage.visible = false
	$ServerCreationFailedMessage.visible = false
	$DifferingVersionMessage.visible = false
	
	visible = false


func connection_failed():
	$ConnectingMessage.visible = false
	$ConnectionFailedMessage.visible = true
	$FailureTimer.start()
	$DotTimer.stop()


func server_creation_failed():
	$CreatingServerMessage.visible = false
	$ServerCreationFailedMessage.visible = true
	$FailureTimer.start()
	$DotTimer.stop()


func invalid_code():
	$ConnectingMessage.visible = false
	$InvalidCodeMessage.visible = true
	$FailureTimer.start()
	$DotTimer.stop()


func _on_DotTimer_timeout():
	dots += 1
	if dots > MAX_DOTS:
		dots = 1
	var message = CONNECTING_MESSAGE
	if net_type == NetworkType.SERVER:
		message = CREATING_SERVER_MESSAGE
		
	for _i in range(dots):
		message += " ."
	if net_type == NetworkType.SERVER:
		$CreatingServerMessage.text = message
	else:
		$ConnectingMessage.text = message


func _on_FailureTimer_timeout():
	for message in get_tree().get_nodes_in_group("network_message"):
		message.visible = false
	hide()
