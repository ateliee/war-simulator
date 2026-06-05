extends RefCounted

var faction
var origin_city
var target_city
var position: Vector2
var power: float
var speed: float = 40.0
var is_fighting: bool = false

func _init(_faction, _origin_city, _target_city, _power: float):
	faction = _faction
	origin_city = _origin_city
	position = _origin_city.position
	target_city = _target_city
	power = _power
