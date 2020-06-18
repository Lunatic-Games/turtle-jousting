extends VideoPlayer


const main_menu = preload("res://ui/main/main_menu.tscn")


func _input(event):
	if event.is_pressed():
		_on_Splash_finished()


func _on_Splash_finished():
	var _err = get_tree().change_scene_to(main_menu)
