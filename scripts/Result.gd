extends Control


func _ready():
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)

	var label = $VBoxContainer/ResultLabel
	label.text = Global.winner_name + " が世界を統一した！"
	label.add_theme_color_override("font_color", Global.winner_color)


func _on_restart_pressed():
	get_tree().change_scene_to_file("res://scenes/Title.tscn")
