extends Node


func _ready():
	var f = ConfigFile.new()
	var err = f.load("user://settings.cfg")
	if err == OK:
		var fullscreen = f.get_value("display", "fullscreen", false)
		if not f.has_section_key("display", "fullscreen"):
			f.set_value("display", "fullscreen", false)
		if fullscreen:
			OS.window_fullscreen = true
			
		var music = f.get_value("audio", "music", 1.0)
		if not f.has_section_key("audio", "music"):
			f.set_value("audio", "music", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),
			linear2db(music))
			
		var sfx = f.get_value("audio", "sfx", 1.0)
		if not f.has_section_key("audio", "sfx"):
			f.set_value("audio", "sfx", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),
			linear2db(sfx))
			
		var voice = f.get_value("audio", "voice", 1.0)
		if not f.has_section_key("audio", "voice"):
			f.set_value("audio", "voice", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"),
			linear2db(voice))
		
		f.save("user://settings.cfg")


func save():
	var f = ConfigFile.new()
	var _err = f.load("user://settings.cfg")
	f.set_value("display", "fullscreen", OS.window_fullscreen)
	
	var music_bus = AudioServer.get_bus_index("Music")
	f.set_value("audio", "music", 
		db2linear(AudioServer.get_bus_volume_db(music_bus)))
		
	var sfx_bus = AudioServer.get_bus_index("SFX")
	f.set_value("audio", "sfx", 
		db2linear(AudioServer.get_bus_volume_db(sfx_bus)))
		
	var voice_bus = AudioServer.get_bus_index("Voice")
	f.set_value("audio", "voice", 
		db2linear(AudioServer.get_bus_volume_db(voice_bus)))
		
	f.save("user://settings.cfg")


func save_last_codes(local, online):
	var f = ConfigFile.new()
	var err = f.load("user://settings.cfg")
	if err == OK:
		f.set_value("network", "last_local_code", local)
		f.set_value("network", "last_online_code", online)
	f.save("user://settings.cfg")


func get_last_local_code():
	var f = ConfigFile.new()
	var err = f.load("user://settings.cfg")
	if err == OK:
		return f.get_value("network", "last_local_code", "")
	return ""


func get_last_online_code():
	var f = ConfigFile.new()
	var err = f.load("user://settings.cfg")
	if err == OK:
		return f.get_value("network", "last_online_code", "")
	return ""
