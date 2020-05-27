extends Node2D


export (bool) var MENU_VERSION = false

const player_scene = preload("res://player/player.tscn")
const duel_indicator_scene = preload("res://game/duel_indicator/duel_indicator.tscn")
const powerup_scenes = [preload("res://powerups/judgement.tscn"),
	preload("res://powerups/lightning_rod.tscn"),
	preload("res://powerups/mead.tscn")]

var duels = []


# Setup game and disable features if this is a menu version
func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if MENU_VERSION:
		$GameTimerLabel.visible = false
		set_process_input(false)
	else:
		randomize()
		set_process(false)
		$GameTimerLabel.text = str($GameTimer.wait_time)
		$VisorTransition.rpc_config("bring_down", MultiplayerAPI.RPC_MODE_REMOTE)
		$VisorTransition.lift_up()


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
		$PausedMenu.popup_centered(Vector2(1024, 576))
		get_tree().set_input_as_handled()


# Create a new player with the given data
func add_player(number, net_id, data = {}):
	var new_player = player_scene.instance()
	new_player.name = "Player" + str(number)
	new_player.load_data(data)
	new_player.set_network_master(net_id)
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
	get_tree().paused = false


# The game begins
func start():
	set_player_process_input(true)
	set_process(true)
	$GameTimer.start()
	$PowerupSpawnTimer.start()


# Spawn a powerup
func _spawn_powerup():
	var powerup_scene = powerup_scenes[randi() % len(powerup_scenes)]
	var powerup = powerup_scene.instance()
	$YSort.add_child(powerup)
	powerup.global_position = furthest_powerup_spawn_position()
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


# Show duel indicator
func duel_started(p1, p2):
	if duels.has([p1, p2]) or duels.has([p2, p1]):
		print("Duplicate duel")
		return
	var duel_indicator = duel_indicator_scene.instance()
	duel_indicator.display(p1, p2)
	duel_indicator.connect("decided", self, "_on_DuelIndicator_decided")
	add_child(duel_indicator)
	duels.append([p1, p2])


# Hide duel indicator
func _on_DuelIndicator_decided(indicator):
	var p1 = indicator.player_1
	var p2 = indicator.player_2
	if duels.has([p1, p2]):
		duels.remove(duels.find([p1, p2]))
	elif duels.has([p2, p1]):
		duels.remove(duels.find([p2, p1]))
	indicator.queue_free()


# Resume handling player input
func _on_PausedMenu_popup_hide():
	set_player_process_input(true)


# Transition to lobby
func _on_PausedMenu_return_to_lobby():
	$VisorTransition.bring_down(self, "_return_to_lobby")
	if get_tree().network_peer:
		$VisorTransition.rpc("bring_down")


# Change to lobby
func _return_to_lobby():
	if !get_tree().network_peer:
		get_tree().paused = false
	get_parent().get_node("Lobby").return_to()
	queue_free()


# Transition to main menu
func _on_PausedMenu_return_to_main_menu():
	$VisorTransition.bring_down(self, "_return_to_main_menu")
	if get_tree().network_peer:
		$VisorTransition.rpc("bring_down")


# Change to main menu
func _return_to_main_menu():
	if !get_tree().network_peer:
		get_tree().paused = false
	var _err = get_tree().change_scene("res://ui/main/main_menu.tscn")


# Sets the process input of all players
func set_player_process_input(process):
	for player in get_tree().get_nodes_in_group("player"):
		player.set_process_input(process)


func _on_VisorTransition_lifted_up():
	$AnimationPlayer.play("countdown")
