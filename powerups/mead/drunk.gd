extends "res://powerups/status.gd"


export (float) var fall_chance_per_second

const susceptible_states = ["controlling/waiting", 
	"controlling/throwing/charging_throw", "controlling/jousting/charging_joust",
	"controlling/throwing/throw_ending", "controlling/jousting/joust_ending"]


func _physics_process(delta):
	var anim_tree = knight.get_node("AnimationTree")
	var in_susceptible_state = false
	for state in susceptible_states:
		if anim_tree.is_in_state(state):
			in_susceptible_state = true
	if !in_susceptible_state:
		return
	
	var chance_per_frame = fall_chance_per_second / 60
	
