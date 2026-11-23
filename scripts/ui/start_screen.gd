extends Control

@export_file("*.tscn") var main_game_scene: String

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if OS.has_feature("web") and quit_button:
		quit_button.hide()

func _on_play_pressed() -> void:
	if main_game_scene != "":
		get_tree().change_scene_to_file(main_game_scene)
	else:
		push_warning("Chưa gắn file scene màn chơi vào biến Main Game Scene!")

func _on_quit_pressed() -> void:
	get_tree().quit()
