extends Area2D


signal died

export (bool) var parrying = false
export (bool) var in_water = true

const MAX_HEALTH = 100

var health = MAX_HEALTH
var player_number
onready var held_weapon = $Reversable/Sprite/BackArm/WeaponHandle/Lance


# Setup
func _ready():
	$Reversable/Sprite/BackArm/WeaponHandle/Lance.set_player(get_parent())
	$AnimationTree.active = true
	$HealthLabel.text = str(health)
	
	if get_tree().network_peer:
		$Reversable.rset_config("scale", MultiplayerAPI.RPC_MODE_REMOTE)
		$CollisionPolygon2D.rset_config("scale", MultiplayerAPI.RPC_MODE_REMOTE)


# Take damage and update health display
func hit(damage):
	health -= damage
	health = max(health, 0)
	$HealthLabel.text = str(health)
	if health == 0:
		print("Ooof, I'm dead")
		emit_signal("died")
	

# Sets facing direction (+1 right, -1 left)
func set_direction(dir_sign):
	$Reversable.scale.x = dir_sign * abs($Reversable.scale.x)
	$CollisionPolygon2D.scale.x = dir_sign * abs($CollisionPolygon2D.scale.x)
	if get_tree().network_peer and is_network_master():
		$Reversable.rset("scale", $Reversable.scale)
		$CollisionPolygon2D.rset("scale", $CollisionPolygon2D.scale)
	

# Update idle state based on movement
func moved(movement):
	if movement and $AnimationTree.is_in_state("idle"):
		$AnimationTree.travel_idle("idle_moving")
	elif !movement and $AnimationTree.is_in_state("idle"):
		if $AnimationTree.is_in_idle_state("idle_moving"):
			$AnimationTree.travel_idle("idle_stop_moving")
		else:
			$AnimationTree.travel_idle("idle_resting")


# Modulates pieces for team color
func set_color(color):
	$Reversable/Sprite/MainBody/Chest/Modulate.modulate = color
	$Reversable/Sprite/MainBody/Head/Modulate.modulate = color
	$Reversable/Sprite/BackArm/WeaponHandle/Lance.set_color(color)
