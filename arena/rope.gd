extends Path2D


export (NodePath) var buoy1
export (NodePath) var buoy2

var center_pos

func _ready():
	center_pos = curve.get_point_position(1)


func _physics_process(_delta):
	var left_hook = get_node(buoy1).get_node("Hook")
	var right_hook = get_node(buoy2).get_node("Hook")
	curve.set_point_position(0, left_hook.global_position - global_position)
	curve.set_point_position(2, right_hook.global_position - global_position)
	var left_bob = get_node(buoy1).bob_depth()
	var right_bob = get_node(buoy2).bob_depth()
	curve.set_point_position(1, Vector2(center_pos.x, center_pos.y + left_bob + right_bob))
	update()


func _draw():
	draw_polyline(curve.get_baked_points(), Color(1, 1, 1, 1), 1)
