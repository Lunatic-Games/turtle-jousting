extends Node


var id
var player
var knight
var duel_indicator
var joust_direction_set = false


func _ready():
	assert(get_parent().is_in_group("player"))
	randomize()
	player = get_parent()
	knight = player.get_node("Knight")
	id = player.device_id


func _physics_process(_delta):
	if !player.is_processing_input():
		return
	if !player.has_node("Knight"):
		var dir = knight.global_position - player.global_position
		set_joy_direction(dir.normalized())
		return
	if knight.get_node("AnimationTree").is_in_state("flying_off/mounting"):
		set_joy_direction(Vector2(0, 0))
		return
	if player.get_node("AnimationTree").is_in_state("controlling/waiting"):
		press_action("joust")
		if !joust_direction_set:
			var joust_direction = Vector2((randf() - 0.5) * 2, (randf() - 0.5) * 2).normalized()
			set_joy_direction(joust_direction)
			joust_direction_set = true
		return
	if player.get_node("AnimationTree").is_in_state("controlling/jousting/charging_joust"):
		if player.joust_charge == player.MAX_JOUST_CHARGE:
			release_action("joust")
		joust_direction_set = false


func move_towards(pos):
	set_joy_direction(pos - player.global_position)


func press_action(action):
	var ev = InputEventAction.new()
	ev.device = id
	ev.action = action
	ev.pressed = true
	get_tree().input_event(ev)


func release_action(action):
	var ev = InputEventAction.new()
	ev.device = id
	ev.action = action
	ev.pressed = false
	get_tree().input_event(ev)


func dodge(direction):
	set_joy_direction(direction)
	press_action("dodge")
	release_action("dodge")


func parry():
	press_action("parry")
	release_action("parry")


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
