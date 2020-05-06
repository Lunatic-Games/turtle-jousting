extends ColorRect

func reset():
	$CenterContainer/Name.text = "Press A to join"
	
func player_loaded(number):
	$CenterContainer/Name.text = "Player " + str(number)
