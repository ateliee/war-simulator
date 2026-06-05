extends RefCounted

var name: String = ""
var color: Color = Color.WHITE
var cities: Array = []

func _init(_name: String, _color: Color):
	name = _name
	color = _color

func get_total_power() -> float:
	var total = 0.0
	for c in cities:
		total += c.power
	return total

func is_alive() -> bool:
	return cities.size() > 0
