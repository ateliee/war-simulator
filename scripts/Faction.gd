extends RefCounted

var name: String
var color: Color
var total_power: float

func _init(_name: String, _color: Color, _power: float):
	self.name = _name
	self.color = _color
	self.total_power = _power

func is_alive() -> bool:
	return total_power > 0
