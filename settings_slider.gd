extends HBoxContainer


const SLIDE_SPEED = 100
const SLIDE_JUMP = 5

var held = false

	
func _process(delta):
	if held:
		if Input.is_action_pressed("ui_right"):
			$Slider.value += SLIDE_SPEED * delta
		if Input.is_action_pressed("ui_left"):
			$Slider.value -= SLIDE_SPEED * delta


func _on_Slider_focus_entered():
	$Label.pressed = true


func _on_Slider_focus_exited():
	$Label.pressed = false
	$HoldTimer.stop()
	held = false


func _on_Slider_gui_input(_event):
	if Input.is_action_just_pressed("ui_right") and $HoldTimer.is_stopped():
		$HoldTimer.start()
		$Slider.value += SLIDE_JUMP
	if Input.is_action_just_pressed("ui_left") and $HoldTimer.is_stopped():
		$HoldTimer.start()
		$Slider.value -= SLIDE_JUMP
	if Input.is_action_just_released("ui_left") and !Input.is_action_pressed("ui_right"):
		$HoldTimer.stop()
		held = false
	if Input.is_action_just_released("ui_right") and !Input.is_action_pressed("ui_left"):
		$HoldTimer.stop()
		held = false



func _on_HoldTimer_timeout():
	held = true
