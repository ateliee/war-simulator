extends RefCounted

var faction
var origin_city
var target_city
var position: Vector2
var power: float
var speed: float = 40.0
var is_fighting: bool = false
var is_sea_route: bool = false


func _init(_faction, _origin_city, _target_city, _power: float, _is_sea_route: bool = false):
	faction = _faction
	origin_city = _origin_city
	position = _origin_city.position
	target_city = _target_city
	power = _power
	is_sea_route = _is_sea_route
