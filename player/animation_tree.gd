extends AnimationTree


onready var playback = get("parameters/playback")
onready var idle_playback = get("parameters/idle/playback")
onready var knight_tree = get_node("../Knight/AnimationTree")
onready var knight_playback = knight_tree.get("parameters/playback")
onready var knight_idle_playback = knight_tree.get("parameters/idle/playback")
var knight_on = true


func _ready():
	pass


func _process(_delta):
	pass
	
	
func is_in_state(name):
	return playback.get_current_node() == name
	
	
func is_resting():
	if playback.get_current_node() != "idle":
		return false
	return idle_playback.get_current_node() == "idle_resting"


func is_moving():
	if playback.get_current_node() != "idle":
		return false
	return idle_playback.get_current_node() == "idle_moving"


func idle():
	travel_both("idle")
	
	
func rest():
	travel_both("idle")
	travel_both("idle_resting", true)


func move():
	travel_both("idle")
	travel_both("idle_moving", true)


func stop_moving():
	travel_both("idle")
	travel_both("idle_stop_moving", true)


func charge_joust():
	travel_both("charging_joust")


func begin_joust():
	travel_both("jousting")
	

func joust_ended():
	playback.travel("joust_ended")
	knight_playback.travel("joust_ended")


func parry():
	travel_both("parrying")


func dodge():
	travel_both("dodging")


func knight_picked_up():
	knight_tree = get_node("../Knight/AnimationTree")
	knight_playback = knight_tree.get("parameters/playback")
	knight_idle_playback = knight_tree.get("parameters/idle/playback")
	knight_on = true
	travel_both("mounting")
	

func knight_flying_off():
	knight_playback.travel("flying_off")
	knight_on = false


func travel_both(name, idle_pb=false):
	if idle_pb:
		idle_playback.travel(name)
	else:
		playback.travel(name)
	if knight_on and idle_pb:
		knight_idle_playback.travel(name)
	elif knight_on:
		knight_playback.travel(name)
