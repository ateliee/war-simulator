extends RefCounted

var faction
var origin: Vector2
var target
var position: Vector2
var power: float
var speed: float = 60.0

func _init(_faction, _origin: Vector2, _target, _power: float):
	faction = _faction
	origin = _origin
	position = _origin
	target = _target
	power = _power
