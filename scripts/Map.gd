extends Node2D

const CityRef = preload("res://scripts/City.gd")
const FactionRef = preload("res://scripts/Faction.gd")

var cities: Array = []
var factions: Array = []
var troops: Array = []
var noise_tex: NoiseTexture2D
@onready var custom_font: FontFile

@onready var background = $Background


func setup(_cities: Array, _factions: Array, _noise: FastNoiseLite):
	cities = _cities
	factions = _factions

	custom_font = preload("res://assets/fonts/NotoSansJP-Bold.otf")

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

	update_city_powers(cities)


func update_city_powers(current_cities: Array):
	if background.material == null:
		return
	var powers_array = PackedFloat32Array()
	var color_array = PackedColorArray()
	for c in current_cities:
		powers_array.append(max(c.power, 1.0))
		color_array.append(c.faction.color)

	background.material.set_shader_parameter("city_powers", powers_array)
	background.material.set_shader_parameter("city_colors", color_array)


func update_active_troops(_troops: Array):
	troops = _troops


func _process(_delta):
	queue_redraw()


func _draw():
	var font_size = 14
	for c in cities:
		draw_circle(c.position, 6.0, Color.BLACK)

		if c.is_capital:
			draw_circle(c.position, 5.0, Color.YELLOW)
			draw_circle(c.position, 3.0, c.faction.color)
		else:
			draw_circle(c.position, 4.0, c.faction.color)

		var display_name = c.name
		if c.is_capital:
			display_name = "★" + c.name

		var string_size = custom_font.get_string_size(
			display_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size)
		var text_pos = c.position + Vector2(-string_size.x / 2.0, -10)

		draw_string_outline(
			custom_font,
			text_pos,
			display_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size,
			2,
			Color.BLACK
		)
		draw_string(
			custom_font,
			text_pos,
			display_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size,
			Color.WHITE
		)

	# 部隊（三角）の描画
	for t in troops:
		# 進行方向を取得
		var dir = (t.target_city.position - t.origin_city.position).normalized()
		_draw_triangle(t.position, dir, t.faction.color, t.is_fighting)


func _draw_triangle(pos: Vector2, dir: Vector2, color: Color, is_fighting: bool):
	if dir.length() < 0.1:
		return

	var size = 16.0

	# 戦闘中（国境張り付き中）は少しだけ前に押し出すように描画
	var center = pos
	if is_fighting:
		center += dir * 6.0

	# シンプルな二等辺三角形の計算
	var tip = center + dir * size
	var right = center + dir.rotated(PI * 0.8) * size
	var left = center + dir.rotated(-PI * 0.8) * size

	var pts = PackedVector2Array([tip, right, left])
	draw_polygon(pts, PackedColorArray([color, color, color]))

	# アウトライン
	var pts_outline = PackedVector2Array([tip, right, left, tip])
	draw_polyline(pts_outline, Color.BLACK, 2.0)


func get_adjacency_list() -> Array:
	var points = PackedVector2Array()
	for c in cities:
		points.append(c.position)

	var delaunay = Geometry2D.triangulate_delaunay(points)
	var adjacency = []

	for i in range(0, delaunay.size(), 3):
		var idx0 = delaunay[i]
		var idx1 = delaunay[i + 1]
		var idx2 = delaunay[i + 2]

		_add_edge_if_gabriel(adjacency, cities[idx0], cities[idx1])
		_add_edge_if_gabriel(adjacency, cities[idx1], cities[idx2])
		_add_edge_if_gabriel(adjacency, cities[idx2], cities[idx0])

	return adjacency


func _add_edge_if_gabriel(adj_list: Array, c1, c2):
	var mid = (c1.position + c2.position) / 2.0
	var radius_sq = c1.position.distance_squared_to(mid)

	var is_valid = true
	for c3 in cities:
		if c3 == c1 or c3 == c2:
			continue
		if c3.position.distance_squared_to(mid) < radius_sq:
			is_valid = false
			break

	if not is_valid:
		return

	var pair1 = [c1, c2]
	var found = false
	for p in adj_list:
		if (p[0] == c1 and p[1] == c2) or (p[0] == c2 and p[1] == c1):
			found = true
			break
	if not found:
		adj_list.append(pair1)
