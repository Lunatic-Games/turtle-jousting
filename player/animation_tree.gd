extends AnimationTree


onready var playback = get("parameters/playback")
onready var idle_playback = get("parameters/idle/playback")


# Returns true if state is name
func is_in_state(name):
	return playback.get_current_node() == name


# Returns true if state is idle and idle state is name
func is_in_idle_state(name):
	if !is_in_state("idle"):
		return false
	return idle_playback.get_current_node() == name


# Travel to name
remote func travel(name):
	playback.travel(name)
	if get_tree().network_peer and is_network_master():
		rpc("travel", name)


# Travel to idle and travel to name within idle
remote func travel_idle(name):
	idle_playback.travel(name)
	if get_tree().network_peer and is_network_master():
		rpc("travel_idle", name)

