extends Area2D


signal dead
signal knocked_off
signal lance_duel

export (bool) var parrying = false
export (bool) var in_water = true

const MAX_HEALTH = 100
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
	emit_signal("knocked_off", knockback_direction)


func _on_Lance_hit_weapon(other_weapon):
	var other_player
	for player in get_tree().get_nodes_in_group("player"):
		if player.is_a_parent_of(other_weapon):
			other_player = player
			break
	if !other_player:
		print("Couldn't find owner of weapon")
		return
	emit_signal("lance_duel", other_player)
	

func set_direction(dir_sign):
	$Reversable.scale.x = dir_sign * abs($Reversable.scale.x)
	$CollisionShape2D.scale.x = dir_sign * abs($CollisionShape2D.scale.x)
	
	
func set_color(color):
	$Reversable/Sprite/Back_Arm/Lance_Front/Modulate.modulate = color
	$Reversable/Sprite/Main_Body/Chest/Modulate.modulate = color
	$Reversable/Sprite/Main_Body/Head/Modulate.modulate = color
