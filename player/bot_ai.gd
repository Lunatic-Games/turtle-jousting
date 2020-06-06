extends Node


var id


func _ready():
	assert(get_parent().is_in_group("player"))
	id = get_parent().device_id


func _physics_process(delta):
	set_joy_direction(Vector2(1, 0))
	dodge(Vector2(-1, 0))


func move_towards(pos):
	pass


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

