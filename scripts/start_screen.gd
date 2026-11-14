extends Control

@export_file("*.tscn") var main_game_scene: String

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	if play_button:
		play_button.grab_focus()
		play_button.pressed.connect(_on_play_pressed)
		_setup_button_bounce(play_button)
		
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		_setup_button_bounce(quit_button)
	if OS.has_feature("web") and quit_button:
		quit_button.hide()

func _on_play_pressed() -> void:
	if main_game_scene != "":
		get_tree().change_scene_to_file(main_game_scene)
	else:
		push_warning("Chưa gắn file scene màn chơi vào biến Main Game Scene!")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _setup_button_bounce(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.mouse_entered.connect(func():
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tween := create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
