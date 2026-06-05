extends Node2D

const CityRef = preload("res://scripts/City.gd")
const FactionRef = preload("res://scripts/Faction.gd")

@onready var background = $Background

var cities: Array = []
var factions: Array = []
var noise_tex: NoiseTexture2D

func setup(_cities: Array, _factions: Array, _noise: FastNoiseLite):
	cities = _cities
	factions = _factions
	
	noise_tex = NoiseTexture2D.new()
	noise_tex.noise = _noise
	noise_tex.width = 1920
	noise_tex.height = 1080
	noise_tex.seamless = false
	
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/voronoi.gdshader")
	background.material = mat
	
	mat.set_shader_parameter("noise_tex", noise_tex)
	
	var pos_array = PackedVector2Array()
	for c in cities:
		pos_array.append(c.position)
		
	mat.set_shader_parameter("num_cities", cities.size())
	mat.set_shader_parameter("city_positions", pos_array)
	mat.set_shader_parameter("screen_size", Vector2(1920, 1080))
	
	_update_shader_colors()

func update_faction_powers(current_factions: Array):
	if background.material == null:
		return
	var powers_array = PackedFloat32Array()
	for f in current_factions:
		powers_array.append(max(f.total_power, 1.0))
	background.material.set_shader_parameter("faction_powers", powers_array)

func _process(_delta):
	_update_shader_colors()
	queue_redraw()

func _update_shader_colors():
	if background.material == null:
		return
	var color_array = PackedColorArray()
	var city_factions_array = PackedInt32Array()
	
	for c in cities:
		color_array.append(c.faction.color)
		city_factions_array.append(factions.find(c.faction))
		
	background.material.set_shader_parameter("city_colors", color_array)
	background.material.set_shader_parameter("city_factions", city_factions_array)

func _draw():
	for c in cities:
		draw_circle(c.position, 6.0, Color.BLACK)
		draw_circle(c.position, 4.0, c.faction.color)

func get_adjacency_list() -> Array:
	var points = PackedVector2Array()
	for c in cities:
		points.append(c.position)
		
	var delaunay = Geometry2D.triangulate_delaunay(points)
	var adjacency = []
	
	for i in range(0, delaunay.size(), 3):
		var idx0 = delaunay[i]
		var idx1 = delaunay[i+1]
		var idx2 = delaunay[i+2]
		
		_add_edge(adjacency, cities[idx0], cities[idx1])
		_add_edge(adjacency, cities[idx1], cities[idx2])
		_add_edge(adjacency, cities[idx2], cities[idx0])
		
	return adjacency

func _add_edge(adj_list: Array, c1, c2):
	var pair1 = [c1, c2]
	var pair2 = [c2, c1]
	
	var found = false
	for p in adj_list:
		if (p[0] == c1 and p[1] == c2) or (p[0] == c2 and p[1] == c1):
			found = true
			break
	if not found:
		adj_list.append(pair1)
