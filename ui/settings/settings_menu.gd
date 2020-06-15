extends Popup


var bus_layout = preload("res://audio_settings.tres")


func _ready():
	AudioServer.set_bus_layout(bus_layout)
	var level = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	var music_slider = $VBoxContainer/MusicContainer/Slider
	music_slider.value = music_slider.max_value * db2linear(level)
	
	level = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	var sfx_slider = $VBoxContainer/SFXContainer/Slider
	sfx_slider.value = sfx_slider.max_value * db2linear(level)


# Check for cancel
func _input(event):
	if visible and event.is_action("ui_cancel") and event.pressed:
		_on_BackButton_pressed()


# Hide self, other menus should connect to signal emitted on hide
func _on_BackButton_pressed():
	hide()


# Toggle vibration
func _on_VibrationButton_pressed():
	var pressed = !$VBoxContainer/VibrationContainer/CheckBox.pressed
	$VBoxContainer/VibrationContainer/CheckBox.pressed = pressed


# Toggle fullscreen
func _on_FullscreenButton_pressed():
	var pressed = !$VBoxContainer/FullscreenContainer/CheckBox.pressed
	$VBoxContainer/FullscreenContainer/CheckBox.pressed = pressed
	OS.window_fullscreen = pressed


func _on_MusicSlider_value_changed(value):
	var ratio = value / $VBoxContainer/MusicContainer/Slider.max_value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),
		linear2db(ratio))
	var _err = ResourceSaver.save("audio_settings.tres", 
		AudioServer.generate_bus_layout())


func _on_SFXSlider_value_changed(value):
	var ratio = value / $VBoxContainer/SFXContainer/Slider.max_value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),
		linear2db(ratio))
	var _err = ResourceSaver.save("audio_settings.tres", 
		AudioServer.generate_bus_layout())
