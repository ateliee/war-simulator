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
	noise_tex.normalize = false

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
	var pos_array = PackedVector2Array()
	var color_array = PackedColorArray()
	for c in current_cities:
		pos_array.append(c.position)
		color_array.append(c.display_color)

	for t in troops:
		pos_array.append(t.position)
		color_array.append(t.faction.color)

	background.material.set_shader_parameter("num_cities", pos_array.size())
	background.material.set_shader_parameter("city_positions", pos_array)
	background.material.set_shader_parameter("city_colors", color_array)


func update_active_troops(_troops: Array):
	troops = _troops


func _process(delta):
	var color_changed = false
	for c in cities:
		if c.display_color != c.faction.color:
			c.display_color = c.display_color.lerp(c.faction.color, delta * 1.5)
			color_changed = true

	if color_changed or troops.size() > 0:
		update_city_powers(cities)

	queue_redraw()


func _draw():
	# 外交関係の描画（首都間をラインで結ぶ）
	var drawn_pairs = {}
	for f1 in factions:
		if f1.cities.size() == 0:
			continue
		var cap1 = null
		for c in f1.cities:
			if c.is_capital:
				cap1 = c
				break
		if cap1 == null:
			continue

		# 戦争のライン（赤の破線）
		for f2 in f1.wars.keys():
			var pair_key = [f1.name, f2.name]
			pair_key.sort()
			if drawn_pairs.has(str(pair_key)):
				continue
			drawn_pairs[str(pair_key)] = true

			var cap2 = null
			for c in f2.cities:
				if c.is_capital:
					cap2 = c
					break
			if cap2 != null:
				draw_dashed_line(cap1.position, cap2.position, Color(1.0, 0.2, 0.2, 0.7), 4.0, 12.0)

		# 同盟のライン（青の実線）
		for f2 in f1.alliances:
			var pair_key = [f1.name, f2.name]
			pair_key.sort()
			if drawn_pairs.has(str(pair_key)):
				continue
			drawn_pairs[str(pair_key)] = true

			var cap2 = null
			for c in f2.cities:
				if c.is_capital:
					cap2 = c
					break
			if cap2 != null:
				draw_line(cap1.position, cap2.position, Color(0.2, 0.6, 1.0, 0.7), 4.0)

	for c in cities:
		var current_font_size = 14
		var text_color = Color.WHITE

		if c.is_capital:
			current_font_size = 20
			text_color = Color.YELLOW
			draw_circle(c.position, 10.0, Color.BLACK)
			draw_circle(c.position, 7.0, c.faction.color)
		else:
			draw_circle(c.position, 6.0, Color.BLACK)
			draw_circle(c.position, 4.0, c.faction.color)

		# 王都に国旗を描画
		if c.is_capital and c.faction.icon != null:
			var icon_size = Vector2(32, 32)
			var rect = Rect2(c.position - Vector2(16, 65), icon_size)
			draw_texture_rect(c.faction.icon, rect, false)

		var display_name = c.name
		if c.is_capital:
			display_name = "★" + c.name

		var string_size = custom_font.get_string_size(
			display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, current_font_size
		)
		var text_pos = c.position + Vector2(-string_size.x / 2.0, -12)

		draw_string_outline(
			custom_font,
			text_pos,
			display_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			current_font_size,
			3,
			Color.BLACK
		)
		draw_string(
			custom_font,
			text_pos,
			display_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			current_font_size,
			text_color
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


func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _is_sea_route(c1, c2) -> bool:
	var steps = 8
	for i in range(1, steps):
		var p = c1.position.lerp(c2.position, float(i) / steps)
		var uv = p / Vector2(1920.0, 1080.0)
		var dist_uv = uv.distance_to(Vector2(0.5, 0.5))
		var falloff = 1.0 - _smoothstep(0.35, 0.5, dist_uv)
		var noise_val = (noise_tex.noise.get_noise_2dv(p) + 1.0) / 2.0
		noise_val *= falloff
		if noise_val < 0.4:  # land_threshold
			return true
	return false


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

	var is_sea = _is_sea_route(c1, c2)
	var pair1 = [c1, c2, is_sea]
	var found = false
	for p in adj_list:
		if (p[0] == c1 and p[1] == c2) or (p[0] == c2 and p[1] == c1):
			found = true
			break
	if not found:
		adj_list.append(pair1)
