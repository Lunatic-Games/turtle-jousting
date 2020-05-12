extends Popup


enum NetworkType {SERVER, CLIENT}
const CONNECTING_MESSAGE = "Connecting"
const CREATING_SERVER_MESSAGE = "Creating server"
const MAX_DOTS = 3
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
	

func hide():
	$FailureTimer.stop()
	$DotTimer.stop()
	$ConnectingMessage.visible = false
	$CreatingServerMessage.visible = false
	$ConnectionFailedMessage.visible = false
	$InvalidCodeMessage.visible = false
	$ServerCreationFailedMessage.visible = false
	
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
	hide()
