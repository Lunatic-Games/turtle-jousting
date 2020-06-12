extends Node


var id
var player
var knight


func _ready():
	assert(get_parent().is_in_group("player"))
	player = get_parent()
	knight = player.get_node("Knight")
	id = player.device_id


func _physics_process(_delta):
	var closest_player = get_closest_player()
	var closest_powerup = get_closest_powerup()
	if !closest_player and !closest_powerup:
		return
	
	if (!closest_player or closest_powerup 
			and closest_comparison(closest_powerup, closest_player)):
		move_towards(closest_powerup.global_position)
	else:
		move_towards(closest_player.global_position)
		


func move_towards(pos):
	set_joy_direction(pos - player.global_position)


func charge_joust():
	var ev = InputEventAction.new()
	ev.device = id
	ev.action = "joust"
	ev.pressed = true
	get_tree().input_event(ev)


func release_joust():
	var ev = InputEventAction.new()
	ev.device = id
	ev.action = "joust"
	ev.pressed = false
	get_tree().input_event(ev)


func dodge(direction):
	set_joy_direction(direction)
	var ev = InputEventAction.new()
	ev.device = id
	ev.action = "dodge"
	ev.pressed = true
	get_tree().input_event(ev)


func parry():
	var ev = InputEventAction.new()
	ev.device = id
	ev.action = "parry"
	ev.pressed = true
	get_tree().input_event(ev)


func set_joy_direction(vec):
	var ev = InputEventJoypadMotion.new()
	ev.device = id
	ev.axis = JOY_AXIS_0
	ev.axis_value = vec.x
	get_tree().input_event(ev)
	
	ev = InputEventJoypadMotion.new()
	ev.device = id
	ev.axis = JOY_AXIS_1
	ev.axis_value = vec.y
	get_tree().input_event(ev)


func get_closest_player():
	var players = get_tree().get_nodes_in_group("player")
	players.erase(player)
	if !players:
		return null
	players.sort_custom(self, "closest_comparison")
	return players[0]


func get_closest_powerup():
	var powerups = get_tree().get_nodes_in_group("powerup")
	if !powerups:
		return null
	powerups.sort_custom(self, "closest_comparison")
	return powerups[0]


func get_distance_to(obj):
	return (obj.global_position - player.global_position).length()


func closest_comparison(a, b):
	if !a and b:
		return b
	if !b and a:
		return a
	return get_distance_to(a) < get_distance_to(b)
