extends Control

const COLOR_NAMES = ["Red", "Blue", "Green", "Yellow"]
const COLORS = [Color("ac4141"), Color("1a7586"), Color("299e57"), Color("b0a335")]

var color_i = 0
var capturing_input = false
var device_id
var focused_button = null
var ready = false
var player_number


func _ready():
	set_process_input(false)
	for node in get_tree().get_nodes_in_group("edit_button"):
		if is_a_parent_of(node):
			node.connect("focus_entered", self, "_on_button_focus_entered",
				[node])


func _input(event):
	if get_tree().network_peer and !is_network_master():
		return
	
	var device = event.device
	if event is InputEventKey or event is InputEventMouse:
		device = "keyboard"
	
	if typeof(device) != typeof(device_id):
		if event is InputEventMouse and mouse_over_node(self):
			get_tree().set_input_as_handled()
		return
	if device != device_id:
		return
		
	if capturing_input:
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
			if !mouse_over_node(self):
				get_tree().set_input_as_handled()
			for node in get_tree().get_nodes_in_group("edit_button"):
				if is_a_parent_of(node) and mouse_over_node(node):
					if node != focused_button:
						unhover_button(focused_button)
						focused_button = node
						hover_button(focused_button)
						
			if event is InputEventMouseMotion:
				get_tree().set_input_as_handled()


func load_player(number, player_data={}):
	player_number = number
	capturing_input = true
	set_process_input(true)
	$Cover/Open.visible = false
	set_edit_button_visibility(true)
	color_i = player_data.get("color_i", 0)
	$Background/ColorName.text = COLOR_NAMES[color_i]

	device_id = player_data.get("device_id", null)
	if device_id == null:
		set_edit_button_visibility(false)
	else:
		focused_button = get_node("Background/ColorContainer/LeftArrowContainer/Button")
		focused_button.texture_normal = focused_button.texture_hover
	ready = player_data.get("ready", false)
	if ready:
		player_ready()
	

func reset():
	set_process_input(false)
	color_i = 0
	$Background/ColorName.text = COLOR_NAMES[color_i]
	$Cover/ClosedButton.visible = false
	$Cover/Open.visible = true
	player_number = null
	device_id = null
	ready = false


func get_player_data():
	return { "device_id" : device_id, "number": player_number,
		"color_i" : color_i, "color" : COLORS[color_i], "ready" : ready}


remote func update_color(i):
	color_i = i
	$Background/ColorName.text = COLOR_NAMES[color_i]


func _on_ReadyButton_pressed():
	player_ready()
	if get_tree().network_peer:
		rpc("player_ready")


remote func player_ready():
	ready = true
	capturing_input = false
	set_edit_button_visibility(false)
	$Cover/ClosedButton.visible = true
	set_process_input(false)


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
	$Background/ColorName.text = COLOR_NAMES[color_i]
	if get_tree().network_peer:
		rpc("update_color", color_i)


func _on_RightColorButton_pressed():
	color_i += 1
	if color_i >= len(COLORS):
		color_i = 0
	$Background/ColorName.text = COLOR_NAMES[color_i]
	if get_tree().network_peer:
		rpc("update_color", color_i)
	

func send_data():
	if ready:
		rpc("player_ready")
	rpc("update_color", color_i)


func move_ui(direction):
	focused_button.pressed = false
	focused_button.toggle_mode = false
	unhover_button(focused_button)
	var neighbour_path = focused_button.get_focus_neighbour(direction)
	var neighbour = focused_button.get_node(neighbour_path)
	focused_button = neighbour
	hover_button(focused_button)


func mouse_over_node(node):
	var rect = node.get_rect()
	rect.position = node.rect_global_position
	return rect.has_point(get_global_mouse_position())


func unhover_button(button):
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
	print("Kicking player")


func _on_ClosedButton_focus_entered():
	$Cover/ClosedButton.text = "Kick player?"


func _on_ClosedButton_focus_exited():
	$Cover/ClosedButton.text = "Ready"
