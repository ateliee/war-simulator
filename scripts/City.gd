extends RefCounted

var name: String = ""
var position: Vector2 = Vector2()
var faction = null
var power: float = 20000.0
var max_power: float = 30000.0
var is_capital: bool = false
var display_color: Color = Color.WHITE


func _init(_name: String, _pos: Vector2):
	name = _name
	position = _pos
