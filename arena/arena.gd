extends Node2D


export (bool) var MENU_VERSION = false

const player_scene = preload("res://player/player.tscn")

const powerup_scenes = [preload("res://powerups/bomb_lance_pickup/bomb_lance_pickup.tscn"),
	preload("res://powerups/broom_pickup/broom_pickup.tscn"),
	preload("res://powerups/invis_potion/invis_potion.tscn"),
	preload("res://powerups/judgement/judgement.tscn"),
	preload("res://powerups/lightning_rod/lightning_rod.tscn"),
	preload("res://powerups/mead/mead.tscn")]

var duels = []
var game_done = false
var game_started = false


# Setup game and disable features if this is a menu version
func _ready():
	if MENU_VERSION:
		$GameTimerLabel.visible = false
		$VisorTransition.visible = false
		set_process_input(false)
		add_player(1, 1, {"number": 1, "bot_id": 999})
		add_player(2, 1, {"number": 2, "bot_id": 998})
		add_player(3, 1, {"number": 3, "bot_id": 997})
		add_player(4, 1, {"number": 4, "bot_id": 996})
		all_players_added()
		set_player_process_input(true)
	else:
		randomize()
		set_process(false)
		$GameTimer.wait_time = 120
		$GameTimer.wait_time += 30 * len(get_tree().get_nodes_in_group("knight"))
		$GameTimerLabel.text = str($GameTimer.wait_time)
		$VisorTransition.rpc_config("bring_down", MultiplayerAPI.RPC_MODE_REMOTE)
		$VisorTransition.lift_up()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Update game timer display
func _process(_delta):
	if MENU_VERSION:
		return
	$GameTimerLabel.text = str(ceil($GameTimer.time_left))


# Check for pause
func _input(event):
	if !MENU_VERSION and event.is_action("pause") and event.pressed:
		if !get_tree().network_peer:
			get_tree().paused = true
		set_player_process_input(false)
		$PausedMenu.set_process_input(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$PausedMenu.popup_centered(Vector2(1024, 576))
		get_tree().set_input_as_handled()


# Create a new player with the given data
func add_player(number, net_id, data = {}):
	var new_player = player_scene.instance()
	new_player.name = "Player" + str(number)
	new_player.load_data(data)
	new_player.set_network_master(net_id)
	new_player.connect("lost", self, "_on_Player_lost")
	$YSort.add_child(new_player)


# Set player positions once all have been added
func all_players_added():
	var players = get_tree().get_nodes_in_group("player")
	var num = len(players)
	if num == 0:
		get_tree().paused = false
		return

	var spawn_positions = get_node("SpawnPositions/" + str(num) + "Player")
	var i = 1
	for player in players:
		var spawn_node = spawn_positions.get_node("Player" + str(i))
		player.global_position = spawn_node.global_position
		if spawn_node.global_position.x > 1024 / 2:
			player.invert_start_direction()
		i += 1


remote func games_synced():
	get_tree().paused = false


# The game begins
func start():
	game_started = true
	set_player_process_input(true)
	set_process(true)
	$GameMusic.play()
	$GameTimer.start()
	if get_tree().network_peer and is_network_master():
		$PowerupSpawnTimer.start()
	elif !get_tree().network_peer:
		$PowerupSpawnTimer.start()


# Spawn a powerup
func _spawn_random_powerup():
	var powerup_i = randi() % len(powerup_scenes)
	var pos = furthest_powerup_spawn_position()
	spawn_powerup(powerup_i, pos)
	if get_tree().network_peer:
		rpc("spawn_powerup", powerup_i, pos)


remote func spawn_powerup(i, position):
	var powerup_scene = powerup_scenes[i]
	var powerup = powerup_scene.instance()
	$YSort.add_child(powerup)
	powerup.global_position = position
	if !get_tree().network_peer or is_network_master():
		powerup.connect("picked_up", $PowerupSpawnTimer, "start")


# Determines the powerup spawn location that is furthest from players
func furthest_powerup_spawn_position():
	var values = []
	for spawn in $PowerupPositions.get_children():
		var v = 0
		for player in get_tree().get_nodes_in_group("player"):
			v += abs((player.global_position - spawn.global_position).length())
		values.append(v)
	if !values:
		print("No players to determine spawn location")
		return
	var i = values.find(values.max())
	return $PowerupPositions.get_child(i).global_position


# Check if there is only one player remaining
func _on_Player_lost():
	if MENU_VERSION:
		return
	
	if len(get_tree().get_nodes_in_group("player")) <= 1 and !game_done:
		set_player_process_input(false)
		game_done = true
		$GameTimer.stop()
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 0.5
		add_child(timer)
		timer.connect("timeout", self, "_game_end")
		timer.start()


func _game_end():
	if len(get_tree().get_nodes_in_group("player")) == 1:
		$AnimationPlayer.play("victory")
	elif len(get_tree().get_nodes_in_group("player")) == 0:
		$AnimationPlayer.play("failure")


# Begin transition to return to the lobby
remote func begin_return_to_lobby():
	get_tree().paused = true
	set_player_process_input(false)
	$VisorTransition.bring_down(self, "_return_to_lobby")
	if get_tree().network_peer and is_network_master():
		rpc("begin_return_to_lobby")


# Resume handling player input
func _on_PausedMenu_popup_hide():
	if game_started:
		set_player_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Transition to lobby
func _on_PausedMenu_return_to_lobby():
	$VisorTransition.bring_down(self, "_return_to_lobby")
	if get_tree().network_peer:
		$VisorTransition.rpc("bring_down")


# Change to lobby
func _return_to_lobby():
	queue_free()
	get_parent().get_node("Lobby").return_to()


# Transition to main menu
remote func begin_return_to_main_menu():
	$VisorTransition.bring_down(self, "_return_to_main_menu")
	set_process_input(false)
	if get_tree().network_peer and is_network_master():
		rpc("begin_return_to_main_menu")


# Change to main menu
func _return_to_main_menu():
	get_tree().call_group("player", "remove_from_group", "player")
	get_tree().call_group("knight", "remove_from_group", "knight")
	queue_free()
	get_tree().paused = false
	var _err = get_tree().change_scene("res://ui/main/main_menu.tscn")


# Sets the process input of all players
func set_player_process_input(process):
	for player in get_tree().get_nodes_in_group("player"):
		player.set_process_input(process)


func _on_VisorTransition_lifted_up():
	$AnimationPlayer.play("countdown")


func _on_GameTimer_timeout():
	if len(get_tree().get_nodes_in_group("knight")) == 1:
		$AnimationPlayer.play("times_up")
		return
	for knight in get_tree().get_nodes_in_group("knight"):
		knight.set_health(1)
	$AnimationPlayer.play("sudden_death")


func play_turtle_voice(audio, override=false):
	if $TurtleVoice.playing and !override:
		return
	$TurtleVoice.stream = audio
	$TurtleVoice.play()
	$GameMusic.volume_db = -10


func _on_TurtleVoice_finished():
	$GameMusic.volume_db = 0
