extends Area2D


signal died

export (bool) var parrying = false
export (bool) var on_turtle = true
export (Curve) var flying_velocity

const MAX_HEALTH = 100
const MAX_FLY_DISTANCE = 1024

var health = MAX_HEALTH
var alive = true
var player_number
var flying_knockback
var flying_dist_travelled = 0
onready var weapon_handle = $Reversable/Sprite/BackArm/WeaponHandle


# Setup
func _ready():
	$Reversable/Sprite/BackArm/WeaponHandle.set_player(get_parent())
	$AnimationTree.active = true
	#$HealthLabel.text = str(health)
	
	if get_tree().network_peer:
		$Reversable.rset_config("scale", MultiplayerAPI.RPC_MODE_REMOTE)
		$CollisionPolygon2D.rset_config("scale", MultiplayerAPI.RPC_MODE_REMOTE)


# Fly self through air if flying
func _physics_process(delta):
	if _is_flying():
		var dist_ratio = flying_dist_travelled / MAX_FLY_DISTANCE
		var vel = flying_velocity.interpolate(dist_ratio)
		var movement = flying_knockback.normalized() * vel * delta
		flying_dist_travelled += movement.length()
		if flying_dist_travelled > flying_knockback.length():
			var diff = flying_knockback.length() - flying_dist_travelled
			movement = movement.clamped(max(0, diff))
			$AnimationTree.travel("flying_off/drowning")
		position += movement
		


# Reduce health
func hit(damage, knockback_on_death=Vector2(0, 0)):
	if !alive:
		return
	health -= damage
	health = max(health, 0)
	set_health(health, knockback_on_death)


func heal(amount):
	if !alive:
		return
	health += amount
	health = min(health, 100)


# Set health to a value
func set_health(new_health, knockback_on_death=Vector2(0,0)):
	if !alive:
		return
	health = new_health
	#$HealthLabel.text = str(health)
	if health == 0:
		if on_turtle and get_parent().is_in_group("player"):
			get_parent().knock_knight_off(knockback_on_death)
		alive = false
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
	if movement and $AnimationTree.is_in_state("controlling/waiting/idling"):
		$AnimationTree.travel("controlling/waiting/moving")
	elif !movement and $AnimationTree.is_in_state("controlling/waiting/moving"):
		$AnimationTree.travel("controlling/waiting/moving_stop")


# Begin flying off the turtle
func fly_off(knockback):
	$AnimationTree.travel("flying_off/flying_off")
	flying_knockback = knockback
	flying_dist_travelled = 0


# Modulates pieces for team color
func set_color(color):
	$Reversable/Sprite/MainBody/Chest/Modulate.modulate = color
	$Reversable/Sprite/MainBody/Head/Modulate.modulate = color
	$Reversable/Sprite/BackArm/WeaponHandle/Lance.set_color(color)


func _on_FlyingHitbox_area_entered(area):
	if area.is_in_group("wall") and _is_flying():
		$AnimationTree.travel("flying_off/drowning")
		flying_knockback = Vector2(0, 0)


func _is_flying():
	return ($AnimationTree.is_in_state("flying_off/flying_off") or
		$AnimationTree.is_in_state("flying_off/flying"))



