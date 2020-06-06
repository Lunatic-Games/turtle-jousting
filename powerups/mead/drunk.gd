extends "res://powerups/status.gd"


export (float) var fall_chance_per_second
export (float) var knockback_on_falloff
export (float) var damage_modifier

const susceptible_states = ["controlling/waiting", 
	"controlling/throwing/charging_throw", "controlling/jousting/charging_joust",
	"controlling/throwing/throw_ending", "controlling/jousting/joust_ending"]

onready var chance_per_frame = fall_chance_per_second / 60


func _ready():
	knight.weapon_handle.set_damage_mod(damage_modifier)


func _physics_process(_delta):
	var anim_tree = knight.get_node("AnimationTree")
	var in_susceptible_state = false
	for state in susceptible_states:
		if anim_tree.is_in_state(state):
			in_susceptible_state = true
	if !in_susceptible_state:
		return
	
	var x = randf()
	if x < chance_per_frame:
		var knockback = Vector2(0, -knockback_on_falloff)
		player.knock_knight_off(knockback)


func _exit_tree():
	knight.weapon_handle.set_damage_mod(1)
