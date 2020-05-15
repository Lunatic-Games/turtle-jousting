extends Node2D

export (bool) var MENU_VERSION = false

const player_scene = preload("res://player/player.tscn")

remote var visor_brought_down_method = "_return_to_main_menu"

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if MENU_VERSION:
		$GameTimerLabel.visible = false
		set_process_input(false)
	else:
		#get_tree().paused = true
		set_process(false)
		$GameTimerLabel.text = str($GameTimer.wait_time)
		$AnimationPlayer.play("countdown")
		$VisorTransition.lift_up()
		$VisorTransition.rpc_config("bring_down", MultiplayerAPI.RPC_MODE_REMOTE)

func _process(delta):
	if MENU_VERSION:
		return
	
	$GameTimerLabel.text = str(ceil($GameTimer.time_left))
	
	
func _input(event):
	if !MENU_VERSION and event.is_action("pause") and event.pressed:
		if !get_tree().network_peer:
			get_tree().paused = true
		set_player_process_input(false)
		$PausedMenu.set_process_input(true)
		$PausedMenu.popup_centered(Vector2(1024, 576))
		get_tree().set_input_as_handled()

func add_player(number, net_id, data = {}):
	var new_player = player_scene.instance()
	new_player.name = "Player" + str(number)
	new_player.load_data(data)
	new_player.set_network_master(net_id)
	$YSort.add_child(new_player)


func all_players_added():
	get_tree().paused = false
	set_player_process_input(false)
	var players = get_tree().get_nodes_in_group("player")
	var num = len(players)
	if num == 0:
		return
	var spawn_positions = get_node("SpawnPositions/" + str(num) + "Player")
	var i = 1
	for player in players:
		var spawn_node = spawn_positions.get_node("Player" + str(i))
		player.global_position = spawn_node.global_position
		if spawn_node.global_position.x > 1024 / 2:
			player.invert_start_direction()
		player.update_sprite_direction(Vector2(0, 0))
		i += 1


func start():
	set_player_process_input(true)
	set_process(true)
	$GameTimer.start()
	
	
func set_player_process_input(process):
	for player in get_tree().get_nodes_in_group("player"):
		player.set_process_input(process)


func _on_PausedMenu_popup_hide():
	set_player_process_input(true)


func _on_PausedMenu_return_to_lobby():
	$VisorTransition.bring_down()
	visor_brought_down_method = "_return_to_lobby"
	if get_tree().network_peer:
		$VisorTransition.rpc("bring_down")
		rset("visor_brought_down_method", "_return_to_lobby")


func _return_to_lobby():
	if !get_tree().network_peer:
		get_tree().paused = false
	get_parent().get_node("Lobby").return_to()
	queue_free()


func _on_VisorTransition_brought_down():
	call(visor_brought_down_method)


func _on_PausedMenu_return_to_main_menu():
	$VisorTransition.bring_down()
	visor_brought_down_method = "_return_to_main_menu"
	if get_tree().network_peer:
		$VisorTransition.rpc("bring_down")
		rset("visor_brought_down_method", "_return_to_main_menu")


func _return_to_main_menu():
	if !get_tree().network_peer:
		get_tree().paused = false
	var _err = get_tree().change_scene("res://ui/main/main_menu.tscn")
	queue_free()
