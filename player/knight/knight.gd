extends Area2D


signal died

export (bool) var parrying = false
export (bool) var in_water = true

const MAX_HEALTH = 100

var health = MAX_HEALTH
var number


# Setup
func _ready():
	make_collisions_unique()
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
	$CollisionShape2D.scale.x = dir_sign * abs($CollisionShape2D.scale.x)
	if get_tree().network_peer and is_network_master():
		$Reversable.rset("scale", $Reversable.scale)
		$CollisionShape2D.rset("scale", $CollisionShape2D.scale)
	

# Modulates pieces for team color
func set_color(color):
	$Reversable/Sprite/Main_Body/Chest/Modulate.modulate = color
	$Reversable/Sprite/Main_Body/Head/Modulate.modulate = color
	$Sprite/BackArm/WeaponHandle/Lance.set_color(color)


# Stop knights from sharing collision shape (needed for animations)
func make_collisions_unique():
	$CollisionPolygon2D.polygon = $CollisionPolygon2D.polygon.duplicate()
