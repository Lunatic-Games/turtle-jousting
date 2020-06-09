extends Sprite


const MAX_HEALTH = 100.0
const CHANGE_RATE = 100.0
const IMG_RIGHT = 879.0
const IMG_LEFT = 145.0

var actual = 100.0
var previous = 100.0
var changing = false


func _ready():
	$Damage.texture = $Damage.texture.duplicate(true)
	$Health.texture = $Health.texture.duplicate(true)


func set_health(health):
	if actual == health:
		return
	$AnimationPlayer.play("hit")
	update_texture($Health, health / MAX_HEALTH)
	actual = health
	changing = false
	$Delay.start()


func _physics_process(delta):
	if !changing:
		return
	if previous > actual:
		previous -= CHANGE_RATE * delta
		if previous < actual:
			previous = actual
			changing = false
	elif previous < actual:
		previous += CHANGE_RATE * delta
		if previous > actual:
			previous = actual
			changing = false
	update_texture($Damage, previous / MAX_HEALTH)
	

func _on_Delay_timeout():
	changing = true


# Changes sprite texture to show a percentage (0.0 to 1.0) of the texture
func update_texture(sprite, percent):
	sprite.region_rect.size.x = (IMG_RIGHT - IMG_LEFT) * percent + IMG_LEFT
	sprite.position.x = -(1080 - sprite.region_rect.size.x) / 2
