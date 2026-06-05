extends Node2D

const FactionRef = preload("res://scripts/Faction.gd")
const CityRef = preload("res://scripts/City.gd")

var map_scene = preload("res://scenes/Map.tscn")
var map_instance: Node2D

var factions: Array = []
var cities: Array = []
var noise: FastNoiseLite
var game_time: float = 0.0

@onready var ui_container = CanvasLayer.new()
@onready var faction_list_label = Label.new()
@onready var time_label = Label.new()

func _ready():
	add_child(ui_container)
	ui_container.add_child(faction_list_label)
	faction_list_label.position = Vector2(20, 20)
	faction_list_label.add_theme_font_size_override("font_size", 32)
	faction_list_label.add_theme_color_override("font_color", Color.WHITE)
	faction_list_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	
	ui_container.add_child(time_label)
	time_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	time_label.offset_top = 20
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 48)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	
	_init_factions()
	_init_cities()
	
	map_instance = map_scene.instantiate()
	add_child(map_instance)
	map_instance.setup(cities, factions, noise)

func _init_factions():
	var red = FactionRef.new("赤の帝国", Color(0.8, 0.2, 0.2), randf_range(80000, 100000))
	var blue = FactionRef.new("青の共和国", Color(0.2, 0.4, 0.8), randf_range(80000, 100000))
	var green = FactionRef.new("緑の連邦", Color(0.2, 0.8, 0.3), randf_range(80000, 100000))
	var yellow = FactionRef.new("黄の連合", Color(0.8, 0.8, 0.2), randf_range(80000, 100000))
	var purple = FactionRef.new("紫の王国", Color(0.6, 0.2, 0.8), randf_range(80000, 100000))
	
	factions = [red, blue, green, yellow, purple]

func _init_cities():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	# 周波数を調整し、複数大陸や島が生成されやすくする
	noise.frequency = 0.003
	noise.fractal_octaves = 4
	
	var num_cities = 60 # さらに都市を少し増やして密度を確保
	var screen_size = Vector2(1920, 1080)
	
	var spawned = 0
	var timeout = 0
	while spawned < num_cities and timeout < 10000:
		timeout += 1
		var pos = Vector2(randf_range(50, screen_size.x - 50), randf_range(50, screen_size.y - 50))
		
		# 滑らかなビネット（減衰）マスクを適用し複数大陸化
		var uv = pos / screen_size
		var dist_uv = uv.distance_to(Vector2(0.5, 0.5))
		var falloff = 1.0 - smoothstep(0.35, 0.5, dist_uv)
		
		var n = noise.get_noise_2d(pos.x, pos.y) * 0.5 + 0.5
		n *= falloff
		
		if n > 0.4: # 陸地判定
			var city = CityRef.new("都市" + str(spawned+1), pos)
			city.faction = factions[randi() % factions.size()]
			cities.append(city)
			spawned += 1

func _process(delta):
	game_time += delta
	_update_simulation(delta)
	_update_ui()
	
	if game_time > 2.0:
		_check_win_condition()

func _check_win_condition():
	var alive_factions = factions.filter(func(f): return f.is_alive())
	if alive_factions.size() <= 1:
		if alive_factions.size() == 1:
			var winner = alive_factions[0]
			Global.winner_name = winner.name
			Global.winner_color = winner.color
		else:
			Global.winner_name = "誰もいない"
			Global.winner_color = Color.GRAY
			
		set_process(false)
		get_tree().change_scene_to_file("res://scenes/Result.tscn")

func _update_simulation(delta):
	# 回復
	for faction in factions:
		if faction.is_alive():
			faction.total_power += 400 * delta
	
	var adjacency = map_instance.get_adjacency_list()
	var damage_to_deal = {}
	for f in factions:
		damage_to_deal[f] = 0.0
		
	for pair in adjacency:
		var c1 = pair[0]
		var c2 = pair[1]
		
		if c1.faction != c2.faction and c1.faction.is_alive() and c2.faction.is_alive():
			# ダメージ量を大幅に低下させ、侵攻を遅らせる
			damage_to_deal[c1.faction] += randf_range(500, 700) * delta
			damage_to_deal[c2.faction] += randf_range(500, 700) * delta
			
	for f in factions:
		if f.is_alive():
			f.total_power -= damage_to_deal[f]
			if f.total_power <= 0:
				_annex_faction(f)
				
	map_instance.update_faction_powers(factions)

func _annex_faction(defeated_faction):
	defeated_faction.total_power = 0
	
	var adjacency = map_instance.get_adjacency_list()
	var neighbor_factions = []
	
	for pair in adjacency:
		var c1 = pair[0]
		var c2 = pair[1]
		if c1.faction == defeated_faction and c2.faction != defeated_faction and c2.faction.is_alive():
			if not neighbor_factions.has(c2.faction):
				neighbor_factions.append(c2.faction)
		elif c2.faction == defeated_faction and c1.faction != defeated_faction and c1.faction.is_alive():
			if not neighbor_factions.has(c1.faction):
				neighbor_factions.append(c1.faction)
	
	var winner = null
	if neighbor_factions.size() > 0:
		winner = neighbor_factions[randi() % neighbor_factions.size()]
	else:
		var alive = factions.filter(func(f): return f.is_alive())
		if alive.size() > 0:
			winner = alive[randi() % alive.size()]
			
	if winner != null:
		for city in cities:
			if city.faction == defeated_faction:
				city.faction = winner

func _update_ui():
	# 経過年数（1秒 = 1年）
	var current_year = 2024 + int(game_time)
	time_label.text = "経過年数: %d年" % current_year

	var text = "各国の総兵力:\n"
	for f in factions:
		if f.is_alive():
			text += "%s: %d\n" % [f.name, int(f.total_power)]
		else:
			text += "%s: 滅亡\n" % f.name
	faction_list_label.text = text
