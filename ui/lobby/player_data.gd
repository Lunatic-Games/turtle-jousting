extends Node

var number
var color_i
var net_id
var device_id

func init(n, d_id = null, c_i = 0, n_id = 1):
	number = n
	color_i = c_i
	device_id = d_id
	net_id = n_id
	
func to_dict():
	return {"number" : number, "color_i" : color_i, "net_id" : net_id,
		"device_id" : device_id}
		
func from_dict(dict):
	number = dict.get("number", null)
	device_id = dict.get("device_id", null)
	color_i = dict.get("color_i", 0)
	net_id = dict.get("net_id", 1)
