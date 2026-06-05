extends RefCounted

var name: String
var position: Vector2
var faction # Cannot use static typing without class_name cache to prevent errors

func _init(_name: String, _pos: Vector2):
	self.name = _name
	self.position = _pos
