extends Area2D


signal dead
signal knocked_off
signal stop_joust

export (bool) var parrying = false
export (bool) var in_water = true

const MAX_HEALTH = 100
const KNOCKED_OFF_DISTANCE = 100
var health = MAX_HEALTH
var number


func _ready():
	$HealthLabel.text = str(health)


func hit(damage):
	health -= damage
	health = max(health, 0)
	$HealthLabel.text = str(health)
	if health == 0:
		print("Ooof, I'm dead")
		emit_signal("dead")



func _on_Lance_parried(knockback_direction):
	var new_pos = global_position + knockback_direction * KNOCKED_OFF_DISTANCE
	emit_signal("knocked_off", new_pos)


func _on_Lance_hit_weapon():
	emit_signal("stop_joust")
	

func set_direction(dir_sign):
	$Reversable.scale.x = dir_sign * abs($Reversable.scale.x)
	$CollisionShape2D.scale.x = dir_sign * abs($CollisionShape2D.scale.x)
	
	
func set_color(color):
	$Reversable/Sprite/Back_Arm/Lance_Front/Modulate.modulate = color
	$Reversable/Sprite/Main_Body/Chest/Modulate.modulate = color
	$Reversable/Sprite/Main_Body/Head/Modulate.modulate = color
