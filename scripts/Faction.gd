extends RefCounted

var name: String = ""
var color: Color = Color.WHITE
var icon_path: String = ""
var icon: Texture2D = null
var cities: Array = []

var relations: Dictionary = {}  # 他の勢力との友好度 (-100 ~ 100)
var wars: Dictionary = {}  # 戦争中の勢力 (valueは戦争継続時間)
var alliances: Array = []  # 同盟中の勢力

var birth_rate: float = 0.05  # 出生率
var death_rate: float = 0.03  # 死亡率


func _init(_name: String, _color: Color, _icon_path: String = ""):
	name = _name
	color = _color
	icon_path = _icon_path
	if icon_path != "":
		icon = load(icon_path)

	# 出生率を 4% ~ 12%、死亡率を 2% ~ 8% の間で設定（差し引きで人口が増減）
	birth_rate = randf_range(0.04, 0.12)
	death_rate = randf_range(0.02, 0.08)


func get_total_power() -> float:
	var total = 0.0
	for c in cities:
		total += c.power
	return total


func is_alive() -> bool:
	return cities.size() > 0
