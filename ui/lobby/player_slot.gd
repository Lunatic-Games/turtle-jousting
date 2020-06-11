extends Control


signal removed

const COLORS = [["Red", Color("ac4141")], ["Blue", Color("1a7586")], 
	["Green", Color("299e57")], ["Orange", Color("bf5c00")], 
	["Purple", Color("771cff")], ["Yellow", Color("d4b83f")]]
const FONT_COLOR = Color(1, 1, 1)
const TAKEN_FONT_COLOR = Color(0.5, 0.5, 0.5)

var taken_colors = []
var color_i = 0
var capturing_input = false
var bot_id
var device_id
var focused_button = null
var ready = false
var player_number
var time_readied


func _ready():
	for node in get_tree().get_nodes_in_group("edit_button"):
		if is_a_parent_of(node):
			node.connect("focus_entered", self, "_on_button_focus_entered",
				[node])


func _input(event):
	if !capturing_input or (get_tree().network_peer and !is_network_master()):
		return
	
	if !device_matches_event(event):
		# Stop other devices from hovering self
		if event is InputEventMouse and is_mouse_over_node(self):
			get_tree().set_input_as_handled()
		return
	
	if event is InputEventJoypadButton or event is InputEventKey:
		if focused_button:
			if event.pressed and event.is_action("ui_up"):
				move_ui(MARGIN_TOP)
			elif event.pressed and event.is_action("ui_right"):
				move_ui(MARGIN_RIGHT)
			elif event.pressed and event.is_action("ui_down"):
				move_ui(MARGIN_BOTTOM)
			elif event.pressed and event.is_action("ui_left"):
				move_ui(MARGIN_LEFT)
			elif event.is_action("ui_accept"):
				if event.pressed:
					focused_button.toggle_mode = true
					focused_button.pressed = true
				else:
					if focused_button.pressed:
						focused_button.emit_signal("pressed")
					focused_button.pressed = false
					focused_button.toggle_mode = false
		get_tree().set_input_as_handled()
	elif event is InputEventMouse:
		handle_mouse_event(event)


func handle_mouse_event(event):
	if !is_mouse_over_node(self):
		get_tree().set_input_as_handled()
	for node in get_tree().get_nodes_in_group("edit_button"):
		if is_a_parent_of(node) and is_mouse_over_node(node):
			if node != focused_button:
				unhover_button(focused_button)
				focused_button = node
				hover_button(focused_button)
	if event is InputEventMouseMotion:
		get_tree().set_input_as_handled()


func load_player(number, player_data={}):
	print("LOADING PLAYER: ", player_data)
	player_number = number
	capturing_input = true
	$Cover/Open.visible = false
	set_edit_button_visibility(true)
	update_color(player_data.get("color_i", 0))

	device_id = player_data.get("device_id", null)
	if device_id == null:
		set_edit_button_visibility(false)
	else:
		focused_button = get_node("Background/ColorContainer/LeftArrowContainer/Button")
		focused_button.texture_normal = focused_button.texture_hover
	bot_id = player_data.get("bot_id", null)
	ready = player_data.get("ready", false)
	if ready:
		player_ready()
	else:
		unready()
	

remote func reset():
	print("Resetting slot ", player_number)
	if focused_button:
		unhover_button(focused_button)
	if ready:
		for slot in get_tree().get_nodes_in_group("player_slot"):
			slot.color_freed(COLORS[color_i][0])
	color_i = 0
	$Background/ColorName.text = COLORS[color_i][0]
	$Cover/ClosedButton.visible = false
	$Cover/Open.visible = true
	$Cover/EditLabel.visible = false
	time_readied = null
	player_number = null
	device_id = null
	bot_id = null
	ready = false


func get_player_data():
	return { "device_id" : device_id, "bot_id": bot_id, "number": player_number,
		"color_i" : color_i, "color" : COLORS[color_i][1], "ready" : ready}


remote func update_color(i):
	color_i = i
	$Background/ColorName.text = COLORS[color_i][0]
	update_color_text()
	if get_tree().network_peer and is_network_master():
		rpc("update_color", color_i)


func _on_ReadyButton_pressed():
	if taken_colors.has($Background/ColorName.text):
		return
	time_readied = OS.get_ticks_msec()
	player_ready()

	if get_tree().network_peer and is_network_master():
		rpc("player_ready")
			


remote func player_ready():
	ready = true
	capturing_input = false
	set_edit_button_visibility(false)
	$Cover/ClosedButton.visible = true
	for slot in get_tree().get_nodes_in_group("player_slot"):
		if slot != self:
			print("Taken: ", COLORS[color_i][0])
			slot.color_taken(COLORS[color_i][0])
			if get_tree().network_peer and is_network_master():
				slot.rpc("color_taken", COLORS[color_i][0])
	if is_mouse_over_node($Cover/ClosedButton):
		_on_ClosedButton_focus_entered()
	else:
		_on_ClosedButton_focus_exited()


remote func unready():
	if !ready:
		return
	ready = false
	capturing_input = true
	time_readied = null
	set_edit_button_visibility(true)
	unhover_button(focused_button)
	focused_button = get_node("Background/ColorContainer/LeftArrowContainer/Button")
	hover_button(focused_button)
	$Cover/ClosedButton.visible = false
	$Cover/EditLabel.visible = false
	if get_tree().network_peer and is_network_master():
		rpc("unready")


remote func color_taken(color):
	if !taken_colors.has(color):
		taken_colors.append(color)
	if ready and COLORS[color_i][0] == color:
		unready()
	update_color_text()
	


remote func color_freed(color):
	if ready and COLORS[color_i][0] == color:
		return
	taken_colors.erase(color)
	update_color_text()
	if get_tree().network_peer and is_network_master():
		rpc("color_freed", color)


func update_color_text():
	if taken_colors.has(COLORS[color_i][0]):
		$Background/ColorName.set("custom_colors/font_color", TAKEN_FONT_COLOR)
	else:
		$Background/ColorName.set("custom_colors/font_color", FONT_COLOR)


func set_edit_button_visibility(visible):
	for node in get_tree().get_nodes_in_group("edit_button"):
		if is_a_parent_of(node):
			if get_tree().network_peer and !is_network_master():
				node.visible = false
			else:
				node.visible = visible


func _on_LeftColorButton_pressed():
	color_i -= 1
	if color_i < 0:
		color_i = len(COLORS) - 1
	update_color(color_i)


func _on_RightColorButton_pressed():
	color_i += 1
	if color_i >= len(COLORS):
		color_i = 0
	update_color(color_i)
	

func send_data():
	print("Sending data from slot ", player_number)
	rpc("update_color", color_i)
	if ready:
		rpc("player_ready")
	


func move_ui(direction):
	focused_button.pressed = false
	focused_button.toggle_mode = false
	unhover_button(focused_button)
	var neighbour_path = focused_button.get_focus_neighbour(direction)
	var neighbour = focused_button.get_node(neighbour_path)
	focused_button = neighbour
	hover_button(focused_button)


func is_mouse_over_node(node):
	var rect = node.get_rect()
	rect.position = node.rect_global_position
	return rect.has_point(get_global_mouse_position())


func unhover_button(button):
	if !button:
		return
	if "texture_normal" in button:
		button.texture_normal = button.texture_disabled
	elif "custom_colors/font_color" in button:
		var normal_color = button['custom_colors/font_color_disabled']
		button['custom_colors/font_color'] = normal_color


func hover_button(button):
	if "texture_normal" in button:
		button.texture_normal = button.texture_hover
	elif "custom_colors/font_color" in button:
		var hover_color = button['custom_colors/font_color_hover']
		button['custom_colors/font_color'] = hover_color


func _on_ClosedButton_pressed():
	if (get_tree().network_peer and !is_network_master() 
			and get_tree().get_network_unique_id() != 1):
		return
	_on_RemoveButton_pressed()


func _on_RemoveButton_pressed():
	emit_signal("removed", self)
	reset()
	if get_tree().network_peer and is_network_master():
		rpc("reset")


# Get the device id if its a controller event, or "keyboard" if its keyboard
func get_device(event):
	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"
	return device


# Return true if event device matches device_id
func device_matches_event(event):
	var device = get_device(event)
	if typeof(device) != typeof(device_id):
		return false
	if device != device_id:
		return false
	return true


func _on_ClosedButton_focus_entered():
	if (get_tree().network_peer and !is_network_master() 
			and get_tree().get_network_unique_id() != 1):
		return
	$Cover/ClosedButton.text = "Remove?"
	$Cover/EditLabel.visible = false


func _on_ClosedButton_focus_exited():
	if bot_id:
		$Cover/ClosedButton.text = "Bot ready"
	else:
		$Cover/ClosedButton.text = "Ready"
		$Cover/EditLabel.visible = true
