extends AnimationTree


# Returns true if animation tree is in state
# e.g. is_in_state("controlling/waiting") will return true if in waiting state
func is_in_state(state_path):
	var pieces = _seperate_state_path(state_path)
	var new_path = ""
	for travel_state in pieces[0].split("/"):
		if _get_playback(new_path).get_current_node() != travel_state:
			return false
		if new_path != "":
			new_path += "/"
		new_path += travel_state
	return _get_playback(pieces[0]).get_current_node() == pieces[1]


# Travel to path/state
remote func travel(state_path):
	if get_tree().network_peer and !is_network_master():
		return
	elif get_tree().network_peer:
		rpc("travel", state_path)
	var pieces = _seperate_state_path(state_path)
	var travel_states = pieces[0].split("/")
	var new_path = ""
	for travel_state in travel_states:
		if travel_state == "":
			continue
		if _get_playback(new_path).get_current_node() != travel_state:
			_get_playback(new_path).travel(travel_state)
		if new_path != "":
			new_path += "/"
		new_path += travel_state
	 
	var playback = _get_playback(new_path)
	playback.travel(pieces[1])


# Get current playback of path
func _get_playback(path):
	if path != "":
		path += "/"
	return get("parameters/" + path + "playback")


# Seperates state_path to return [path, state]
func _seperate_state_path(state_path):
	var split = state_path.rfind("/")
	if split == -1:
		return ["", state_path]
	var path = state_path.substr(0, split)
	var state = state_path.substr(split + 1, -1)
	return [path, state]

