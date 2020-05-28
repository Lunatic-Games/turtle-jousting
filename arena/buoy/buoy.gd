extends StaticBody2D



func _ready():
	var anim_length = $AnimationPlayer.get_animation("bob").length
	$AnimationPlayer.advance(rand_range(0, anim_length))
