extends Node2D



func _ready():
	var anim_length = $AnimationPlayer.get_animation("bob").length
	$AnimationPlayer.advance(rand_range(0, anim_length))


func bob_depth():
	var anim_pos = $AnimationPlayer.current_animation_position
	var anim_length = $AnimationPlayer.current_animation_length
	return anim_length / 2 - abs(anim_pos - anim_length / 2)
