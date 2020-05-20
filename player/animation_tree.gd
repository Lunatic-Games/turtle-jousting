extends AnimationTree


onready var playback = get("parameters/playback")
onready var idle_playback = get("parameters/idle/playback")


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
	playback.travel("idle")
	
	
func rest():
	playback.travel("idle")
	idle_playback.travel("idle_resting")
	

func move():
	playback.travel("idle")
	idle_playback.travel("idle_moving")


func stop_moving():
	playback.travel("idle")
	idle_playback.travel("idle_stop_moving")


func charge_joust():
	playback.travel("charging_joust")


func begin_joust():
	playback.travel("jousting")
	

func joust_ended():
	playback.travel("joust_ended")


func parry():
	playback.travel("parrying")


func dodge():
	playback.travel("dodging")
