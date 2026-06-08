extends Node2D

const FactionRef = preload("res://scripts/Faction.gd")
const CityRef = preload("res://scripts/City.gd")
const TroopRef = preload("res://scripts/Troop.gd")

const MAP_SCENE = preload("res://scenes/Map.tscn")

var map_instance: Node2D

var factions: Array = []
var cities: Array = []
var active_troops: Array = []
var noise: FastNoiseLite
var game_time: float = 0.0
var troop_spawn_timer: float = 0.0
var diplomacy_timer: float = 0.0
var ui_timer: float = 0.0

var faction_list_label = RichTextLabel.new()
var diplomacy_label = RichTextLabel.new()
var time_label = Label.new()
var restart_btn = Button.new()
var speed_btn = Button.new()
var speeds = [1.0, 2.0, 3.0, 5.0]
var speed_labels = ["▶", "▶▶", "▶▶▶", "▶▶▶▶▶"]
var current_speed_idx = 0

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
	"ティオ",
	"レイ",
	"サヤ",
	"エラン",
	"ユナ",
	"ファリス",
	"セリス",
	"リオン",
	"カイ",
	"アッシュ",
	"エドガー",
	"マッシュ",
	"セシル",
	"ローザ",
	"リディア",
	"バッツ",
	"ファリス",
	"ガラフ",
	"クルル",
	"ティナ",
	"ロック",
	"セティ",
	"クラウド",
	"ティファ",
	"エアリス",
	"スコール",
	"リノア",
	"ジタン",
	"ガーネット",
	"ビビ",
	"ティーダ",
	"ユウナ",
	"アーロン",
	"ヴァン",
	"アーシェ",
	"ライトニング",
	"ホープ",
	"ノクティス",
	"プロンプト",
	"イグニス",
	"クライヴ",
	"ジル",
	"ジョシュア",
	"ディオン",
	"シド",
	"エド",
	"フレア",
	"ガイ",
	"ヒロ",
	"イオ"
]

@onready var ui_container = CanvasLayer.new()


func _ready():
	add_child(ui_container)
	const CUSTOM_FONT = preload("res://assets/fonts/NotoSansJP-Bold.otf")

	faction_list_label.bbcode_enabled = true
	faction_list_label.fit_content = true
	faction_list_label.scroll_active = false
	faction_list_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	faction_list_label.custom_minimum_size = Vector2(400, 0)
	faction_list_label.add_theme_font_override("normal_font", CUSTOM_FONT)
	faction_list_label.add_theme_font_size_override("normal_font_size", 32)
	faction_list_label.add_theme_color_override("default_color", Color.WHITE)
	faction_list_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	faction_list_label.add_theme_constant_override("outline_size", 6)
	faction_list_label.add_theme_color_override("font_outline_color", Color.BLACK)
	ui_container.add_child(faction_list_label)

	diplomacy_label.bbcode_enabled = true
	diplomacy_label.fit_content = true
	diplomacy_label.scroll_active = false
	diplomacy_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	diplomacy_label.custom_minimum_size = Vector2(800, 0)
	diplomacy_label.add_theme_font_override("normal_font", CUSTOM_FONT)
	diplomacy_label.add_theme_font_size_override("normal_font_size", 32)
	diplomacy_label.add_theme_color_override("default_color", Color.WHITE)
	diplomacy_label.add_theme_constant_override("outline_size", 6)
	diplomacy_label.add_theme_color_override("font_outline_color", Color.BLACK)
	ui_container.add_child(diplomacy_label)

	ui_container.add_child(time_label)
	time_label.position = Vector2(0, 20)
	time_label.size = Vector2(1920, 100)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_override("font", CUSTOM_FONT)
	time_label.add_theme_font_size_override("font_size", 56)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_constant_override("outline_size", 8)
	time_label.add_theme_color_override("font_outline_color", Color.BLACK)

	ui_container.add_child(restart_btn)
	restart_btn.text = "リスタート"
	restart_btn.position = Vector2(1920 - 240, 20)
	restart_btn.size = Vector2(200, 60)
	restart_btn.add_theme_font_override("font", CUSTOM_FONT)
	restart_btn.add_theme_font_size_override("font_size", 32)
	restart_btn.pressed.connect(_on_restart_pressed)

	ui_container.add_child(speed_btn)
	speed_btn.text = "▶ (1x)"
	speed_btn.position = Vector2(40, 20)
	speed_btn.size = Vector2(240, 60)
	speed_btn.add_theme_font_override("font", CUSTOM_FONT)
	speed_btn.add_theme_font_size_override("font_size", 32)
	speed_btn.pressed.connect(_on_speed_btn_pressed)

	_init_factions()
	_init_cities()

	map_instance = MAP_SCENE.instantiate()
	add_child(map_instance)
	map_instance.setup(cities, factions, noise)


func _on_restart_pressed():
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/Title.tscn")


func _on_speed_btn_pressed():
	current_speed_idx = (current_speed_idx + 1) % speeds.size()
	var spd = speeds[current_speed_idx]
	speed_btn.text = "%s (%dx)" % [speed_labels[current_speed_idx], int(spd)]
	Engine.time_scale = spd


func _init_factions():
	var red = FactionRef.new("赤の帝国", Color(0.8, 0.2, 0.2), "res://assets/flags/red.jpg")
	var blue = FactionRef.new("青の共和国", Color(0.2, 0.4, 0.8), "res://assets/flags/blue.jpg")
	var green = FactionRef.new("緑の連邦", Color(0.2, 0.8, 0.3), "res://assets/flags/green.jpg")
	var yellow = FactionRef.new("黄の連合", Color(0.8, 0.8, 0.2), "res://assets/flags/yellow.jpg")
	var purple = FactionRef.new("紫の王国", Color(0.6, 0.2, 0.8), "res://assets/flags/purple.jpg")

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

			var fac = null
			if spawned < factions.size():
				# 最初の5都市は必ず各勢力の首都として1つずつ割り当て
				fac = factions[spawned]
			else:
				var min_dist = 999999.0
				for f in factions:
					if f.cities.size() > 0:
						var cap = f.cities[0]
						var d = pos.distance_to(cap.position)
						if d < min_dist:
							min_dist = d
							fac = f

			city.faction = fac
			city.display_color = fac.color
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
	_update_diplomacy(delta)
	_update_simulation(delta)
	_update_ui(delta)

	if game_time > 2.0:
		_check_win_condition()


func _update_diplomacy(delta):
	diplomacy_timer -= delta

	# 戦争中の国同士の継続時間を更新、および滅亡した国のクリーンアップ
	for f1 in factions:
		if not f1.is_alive():
			continue

		var war_count = f1.wars.size()

		# 滅亡した国をリストから削除
		var keys_to_remove = []
		for f2 in f1.wars.keys():
			if not f2.is_alive():
				keys_to_remove.append(f2)
			else:
				f1.wars[f2] += delta

				# 戦争期間と対象国数に応じて「疲労度」が上昇する（多正面作戦ほど早く疲弊する）
				var exhaustion = f1.wars[f2] * (1.0 + (war_count - 1) * 0.5)
				if exhaustion > 15.0 and randf() < (0.01 * exhaustion) * delta:
					_make_peace(f1, f2)

		for k in keys_to_remove:
			f1.wars.erase(k)

		var i = f1.alliances.size() - 1
		while i >= 0:
			if not f1.alliances[i].is_alive():
				f1.alliances.remove_at(i)
			i -= 1

	if diplomacy_timer > 0:
		return
	diplomacy_timer = 1.0  # 1秒ごとに外交判定

	# 国境を接している国同士の関係性を悪化・改善させる
	var adjacency = map_instance.get_adjacency_list()
	var border_factions = {}
	for pair in adjacency:
		var f1 = pair[0].faction
		var f2 = pair[1].faction
		if f1 != f2:
			if not border_factions.has(f1):
				border_factions[f1] = {}
			if not border_factions.has(f2):
				border_factions[f2] = {}
			border_factions[f1][f2] = true
			border_factions[f2][f1] = true

	var alive_factions = factions.filter(func(f): return f.is_alive())
	for i in range(alive_factions.size()):
		var f1 = alive_factions[i]
		for j in range(i + 1, alive_factions.size()):
			var f2 = alive_factions[j]

			if not f1.relations.has(f2):
				f1.relations[f2] = 0.0
				f2.relations[f1] = 0.0

			# 国境を接していると摩擦が起きやすい（特に関係がマイナスの場合、さらに悪化）
			var is_border = border_factions.has(f1) and border_factions[f1].has(f2)

			if f1.wars.has(f2):
				# 戦争中は関係が常に最低
				f1.relations[f2] = -100.0
				f2.relations[f1] = -100.0
			elif f1.alliances.has(f2):
				# 同盟中は関係が良好
				f1.relations[f2] = min(100.0, f1.relations[f2] + 2.0)
				f2.relations[f1] = min(100.0, f2.relations[f1] + 2.0)
				# 関係が悪化したら同盟破棄の可能性
				if randf() < 0.05 and f1.relations[f2] < 50.0:
					_break_alliance(f1, f2)
			else:
				# 中立状態
				var change = randf_range(-5.0, 5.0)
				if is_border:
					change -= 2.0  # 国境を接していると悪化しやすい

				f1.relations[f2] = clamp(f1.relations[f2] + change, -100.0, 100.0)
				f2.relations[f1] = clamp(f2.relations[f1] + change, -100.0, 100.0)

				# 関係が-50以下で、宣戦布告
				if f1.relations[f2] < -50.0:
					if randf() < 0.2:
						_declare_war(f1, f2)
				# 関係が80以上なら同盟
				elif f1.relations[f2] > 80.0:
					if randf() < 0.2:
						_make_alliance(f1, f2)


func _declare_war(f1, f2):
	if not f1.wars.has(f2):
		f1.wars[f2] = 0.0
		f2.wars[f1] = 0.0
		_break_alliance(f1, f2)


func _make_peace(f1, f2):
	if f1.wars.has(f2):
		f1.wars.erase(f2)
		f2.wars.erase(f1)
		# 停戦後は関係が少しリセットされる
		f1.relations[f2] = -20.0
		f2.relations[f1] = -20.0

		# 戦争が終わったので、進行中の部隊を消滅させる
		var i = active_troops.size() - 1
		while i >= 0:
			var t = active_troops[i]
			if (
				(t.faction == f1 and t.target_city.faction == f2)
				or (t.faction == f2 and t.target_city.faction == f1)
			):
				active_troops.remove_at(i)
			i -= 1


func _make_alliance(f1, f2):
	if not f1.alliances.has(f2):
		f1.alliances.append(f2)
		f2.alliances.append(f1)
		_make_peace(f1, f2)


func _break_alliance(f1, f2):
	if f1.alliances.has(f2):
		f1.alliances.erase(f2)
		f2.alliances.erase(f1)


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
		# 最低限の増加量（移住者や治安維持などによる基礎増加）
		var base_growth = 50.0 * delta
		# 死亡率を加味した自然増減（複利）
		var growth = c.power * (c.faction.birth_rate - c.faction.death_rate) * delta
		var recovery = base_growth + growth

		if c.is_capital:
			recovery += 200.0 * delta  # 首都ボーナス

		c.power = min(c.power + recovery, c.max_power)

	troop_spawn_timer -= delta
	if troop_spawn_timer <= 0:
		troop_spawn_timer = 2.0
		var adjacency = map_instance.get_adjacency_list()
		for pair in adjacency:
			var c1 = pair[0]
			var c2 = pair[1]
			var is_sea = pair[2]

			if c1.faction != c2.faction:
				# 戦争状態の国に対してのみ出撃する
				if c1.faction.wars.has(c2.faction):
					if c1.power > 5000:
						var send_power = c1.power * 0.15
						c1.power -= send_power
						active_troops.append(TroopRef.new(c1.faction, c1, c2, send_power, is_sea))

				if c2.faction.wars.has(c1.faction):
					if c2.power > 5000:
						var send_power = c2.power * 0.15
						c2.power -= send_power
						active_troops.append(TroopRef.new(c2.faction, c2, c1, send_power, is_sea))

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

		var current_speed = t.speed
		if t.is_sea_route:
			current_speed *= 0.33  # 海路は移動速度が1/3
			t.power -= t.power * 0.05 * delta  # 上陸準備や嵐による損耗ペナルティ (5%/sec)

		if dist_to_origin < dist_to_border - 5.0:
			# 国境まで移動する
			t.position += dir * current_speed * delta
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
				if t.is_sea_route:
					dps *= 0.5  # 海からの上陸戦はダメージ半減ペナルティ

				t.target_city.power -= dps * delta
				t.power -= dps * 0.3 * delta  # 自身も損耗

				# 降伏判定：都市の兵力が最大値の15%以下 かつ 攻撃側が守備側の半数以上いる場合、または兵力が0になった場合
				var surrender_threshold = t.target_city.max_power * 0.15
				var is_surrender = (
					t.target_city.power <= surrender_threshold
					and t.power >= t.target_city.power * 0.5
				)
				var is_annihilated = t.target_city.power <= 0

				if is_surrender or is_annihilated:
					_city_annexed(t.target_city, t.faction)
					# 降伏・陥落後、残存する市民（兵力）に加えて、占領した部隊がそのまま駐留軍として合流する
					t.target_city.power = max(t.target_city.power, 100.0) + t.power
					active_troops.remove_at(i)
				elif t.power <= 50.0:
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


func _format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count == 3 and i > 0:
			res = "," + res
			count = 0
	return res


func _update_ui(delta):
	var year = 1000 + int(game_time)
	time_label.text = "AD %d" % year

	ui_timer -= delta
	if ui_timer > 0:
		return
	ui_timer = 1.0  # 1年(1秒)ごとに更新

	var text = "[right]【各国の兵力】\n"
	var dip_text = "【外交状態】\n"
	for f in factions:
		var icon_tag = ""
		if f.icon_path != "":
			icon_tag = "[img=40x40]%s[/img] " % f.icon_path

		if f.is_alive():
			var power_str = _format_number(int(f.get_total_power()))
			text += "%s%s: %s\n" % [icon_tag, f.name, power_str]
			var city_list = []
			for c in f.cities:
				var c_name = c.name.replace("旧都", "").replace("王都", "")
				# 都市名を単語単位で扱わせるため、文字間にWord Joiner(\u2060)を挿入する
				var no_break_name = ""
				for char_idx in range(c_name.length()):
					no_break_name += c_name[char_idx]
					if char_idx < c_name.length() - 1:
						no_break_name += "\u2060"
				city_list.append(no_break_name)
			text += "[font_size=18]  領土: %s[/font_size]\n" % ", ".join(city_list)

			var war_names = []
			for e in f.wars.keys():
				war_names.append(e.name.replace("の", ""))  # 表示をスッキリさせるため「の」を省略
			var ally_names = []
			for a in f.alliances:
				ally_names.append(a.name.replace("の", ""))

			if war_names.size() > 0 or ally_names.size() > 0:
				dip_text += icon_tag + f.name.replace("の", "") + ": "
				var parts = []
				if war_names.size() > 0:
					parts.append("[戦] " + ", ".join(war_names))
				if ally_names.size() > 0:
					parts.append("[同] " + ", ".join(ally_names))
				dip_text += " ".join(parts) + "\n"
		else:
			text += "%s%s: 滅亡\n" % [icon_tag, f.name]
	text += "[/right]"
	faction_list_label.text = text
	diplomacy_label.text = dip_text

	# リッチテキストのサイズを動的に縮小させ、下揃え（アンカー底辺）を維持する
	faction_list_label.reset_size()
	diplomacy_label.reset_size()

	# アンカーに頼らず、直接座標で画面の右下・左下に配置する
	faction_list_label.position = Vector2(
		1920 - faction_list_label.size.x - 40, 1080 - faction_list_label.size.y - 40
	)
	diplomacy_label.position = Vector2(40, 1080 - diplomacy_label.size.y - 40)
