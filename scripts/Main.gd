extends Node2D

const FactionRef = preload("res://scripts/Faction.gd")
const CityRef = preload("res://scripts/City.gd")
const TroopRef = preload("res://scripts/Troop.gd")

var map_scene = preload("res://scenes/Map.tscn")
var map_instance: Node2D

var factions: Array = []
var cities: Array = []
var active_troops: Array = []
var noise: FastNoiseLite
var game_time: float = 0.0
var troop_spawn_timer: float = 0.0

var city_names = [
	"アイゼン",
	"ルカ",
	"バルド",
	"セルフィ",
	"アリア",
	"グラン",
	"オルザ",
	"ドラン",
	"メル",
	"リム",
	"ゼノ",
	"カリン",
	"ノア",
	"シオン",
	"レナ",
	"マリス",
	"ロイド",
	"クロウ",
	"レイ",
	"ユウ",
	"カイ",
	"ルイン",
	"アーク",
	"セシル",
	"ディン",
	"エド",
	"フレア",
	"ガイ",
	"ヒロ",
	"イオ",
	"ジン",
	"ケン",
	"ラン",
	"ミカ",
	"ナツ",
	"オト",
	"ピア",
	"クイン",
	"リタ",
	"サヤ",
	"タマ",
	"ウミ",
	"ヴィオ",
	"ワカ",
	"シト",
	"ヨミ",
	"ザラ"
]

@onready var ui_container = CanvasLayer.new()
@onready var faction_list_label = Label.new()
@onready var time_label = Label.new()
@onready var restart_btn = Button.new()

func _ready():
	add_child(ui_container)
	var custom_font = preload("res://assets/fonts/NotoSansJP-Bold.otf")
	ui_container.add_child(faction_list_label)
	faction_list_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	faction_list_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	faction_list_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	faction_list_label.offset_right = -40
	faction_list_label.offset_bottom = -40
	faction_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	faction_list_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	faction_list_label.add_theme_font_override("font", custom_font)
	faction_list_label.add_theme_font_size_override("font_size", 32)
	faction_list_label.add_theme_color_override("font_color", Color.WHITE)
	faction_list_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	faction_list_label.add_theme_constant_override("outline_size", 6)
	faction_list_label.add_theme_color_override("font_outline_color", Color.BLACK)

	ui_container.add_child(time_label)
	time_label.position = Vector2(0, 20)
	time_label.size = Vector2(1920, 100)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_override("font", custom_font)
	time_label.add_theme_font_size_override("font_size", 56)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_constant_override("outline_size", 8)
	time_label.add_theme_color_override("font_outline_color", Color.BLACK)

	ui_container.add_child(restart_btn)
	restart_btn.text = "リスタート"
	restart_btn.position = Vector2(1920 - 200, 20)
	restart_btn.add_theme_font_override("font", custom_font)
	restart_btn.add_theme_font_size_override("font_size", 32)
	restart_btn.pressed.connect(_on_restart_pressed)

	_init_factions()
	_init_cities()

	map_instance = map_scene.instantiate()
	add_child(map_instance)
	map_instance.setup(cities, factions, noise)


func _on_restart_pressed():
	get_tree().change_scene_to_file("res://scenes/Title.tscn")


func _init_factions():
	var red = FactionRef.new("赤の帝国", Color(0.8, 0.2, 0.2))
	var blue = FactionRef.new("青の共和国", Color(0.2, 0.4, 0.8))
	var green = FactionRef.new("緑の連邦", Color(0.2, 0.8, 0.3))
	var yellow = FactionRef.new("黄の連合", Color(0.8, 0.8, 0.2))
	var purple = FactionRef.new("紫の王国", Color(0.6, 0.2, 0.8))

	factions = [red, blue, green, yellow, purple]


func _init_cities():
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.003
	noise.fractal_octaves = 4

	var num_cities = 60
	var screen_size = Vector2(1920, 1080)

	var spawned = 0
	var timeout = 0
	while spawned < num_cities and timeout < 10000:
		timeout += 1
		var pos = Vector2(randf_range(50, screen_size.x - 50), randf_range(50, screen_size.y - 50))

		var uv = pos / screen_size
		var dist_uv = uv.distance_to(Vector2(0.5, 0.5))
		var falloff = 1.0 - smoothstep(0.35, 0.5, dist_uv)

		var n = noise.get_noise_2d(pos.x, pos.y) * 0.5 + 0.5
		n *= falloff

		if n > 0.4:
			var city_name = "都市"
			if city_names.size() > 0:
				var idx = randi() % city_names.size()
				city_name = city_names[idx]
				city_names.remove_at(idx)

			var city = CityRef.new(city_name, pos)
			var fac = factions[randi() % factions.size()]
			city.faction = fac
			fac.cities.append(city)
			cities.append(city)
			spawned += 1

	for f in factions:
		if f.cities.size() > 0:
			var cap = f.cities[0]
			cap.is_capital = true
			cap.power = 60000.0
			cap.max_power = 60000.0
			cap.name = "王都" + cap.name


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
	for c in cities:
		var recovery = 200.0 * delta
		if c.is_capital:
			recovery = 600.0 * delta
		c.power = min(c.power + recovery, c.max_power)

	troop_spawn_timer -= delta
	if troop_spawn_timer <= 0:
		troop_spawn_timer = 2.0
		var adjacency = map_instance.get_adjacency_list()
		for pair in adjacency:
			var c1 = pair[0]
			var c2 = pair[1]

			if c1.faction != c2.faction:
				if c1.power > 5000:
					var send_power = c1.power * 0.15
					c1.power -= send_power
					active_troops.append(TroopRef.new(c1.faction, c1, c2, send_power))

				if c2.power > 5000:
					var send_power = c2.power * 0.15
					c2.power -= send_power
					active_troops.append(TroopRef.new(c2.faction, c2, c1, send_power))

	var i = active_troops.size() - 1
	while i >= 0:
		var t = active_troops[i]

		# 国境線の位置割合を兵力から計算 (Apollonius graphによる近似)
		var w1 = max(t.origin_city.power, 100.0)
		var w2 = max(t.target_city.power, 100.0)
		var border_ratio = w1 / (w1 + w2)
		var border_pos = t.origin_city.position.lerp(t.target_city.position, border_ratio)

		var dir = (t.target_city.position - t.origin_city.position).normalized()
		var dist_to_origin = t.position.distance_to(t.origin_city.position)
		var dist_to_border = t.origin_city.position.distance_to(border_pos)

		if dist_to_origin < dist_to_border - 5.0:
			# 国境まで移動する
			t.position += dir * t.speed * delta
			t.is_fighting = false
		else:
			# 国境に到達！ここに張り付いて継続ダメージを与える
			t.position = border_pos
			t.is_fighting = true

			if t.target_city.faction == t.faction:
				# 進行中に味方になっていた場合
				t.target_city.power = min(t.target_city.power + t.power, t.target_city.max_power)
				active_troops.remove_at(i)
			else:
				# 敵都市を継続的に削る（押し込む）
				var dps = t.power * 0.8
				t.target_city.power -= dps * delta
				t.power -= dps * 0.3 * delta  # 自身も損耗

				if t.target_city.power <= 0:
					_city_annexed(t.target_city, t.faction)

				if t.power <= 50.0:
					active_troops.remove_at(i)
		i -= 1

	map_instance.update_city_powers(cities)
	map_instance.update_active_troops(active_troops)


func _city_annexed(defeated_city, winner_faction):
	var old_faction = defeated_city.faction
	old_faction.cities.erase(defeated_city)

	defeated_city.faction = winner_faction
	winner_faction.cities.append(defeated_city)

	if defeated_city.is_capital:
		defeated_city.is_capital = false
		defeated_city.name = defeated_city.name.replace("王都", "旧都")
		defeated_city.max_power = 30000.0

	# 占領直後は兵力をほぼゼロ(100)にし、一気に領土が広がる不自然なフラッシュを防止
	defeated_city.power = 100.0


func _update_ui():
	var year = 1000 + int(game_time)
	time_label.text = "AD %d" % year

	var text = "【各国の総兵力】\n"
	for f in factions:
		if f.is_alive():
			text += "%s: %d\n" % [f.name, int(f.get_total_power())]
		else:
			text += "%s: 滅亡\n" % f.name
	faction_list_label.text = text
