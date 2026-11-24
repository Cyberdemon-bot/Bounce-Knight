extends CanvasLayer

@export_file("*.tscn") var start_screen_scene: String = "res://scenes/ui/start_screen_classic.tscn"

@onready var overlay: ColorRect = $Overlay
@onready var bgm_slider: HSlider = %BGMSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var fullscreen_btn: Button = %FullscreenButton
@onready var main_menu_btn: Button = %MainMenuButton
@onready var close_btn: Button = %CloseButton

const TEXT_DARK_COLOR := Color("#2c354d")
var is_in_gameplay: bool = false

func _ready() -> void:
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	
	_init_slider(bgm_slider, "BGM")
	bgm_slider.value_changed.connect(func(val): _set_bus_volume("BGM", val))
	
	_init_slider(sfx_slider, "SFX")
	sfx_slider.value_changed.connect(func(val): _set_bus_volume("SFX", val))
	
	_setup_button(fullscreen_btn)
	fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
	
	_setup_button(main_menu_btn)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	
	_setup_button(close_btn)
	close_btn.pressed.connect(close_menu)

func _process(_delta: float) -> void:
	if overlay.visible:
		_update_fullscreen_text()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Phím ESC
		get_viewport().set_input_as_handled()
		var current_scene := get_tree().current_scene
		if current_scene and current_scene.name == "StartScreenClassic":
			if overlay.visible:
				close_menu()
			return
			
		if overlay.visible:
			close_menu()
		else:
			open_menu(true)

func open_menu(from_gameplay: bool) -> void:
	is_in_gameplay = from_gameplay
	main_menu_btn.visible = from_gameplay
	close_btn.text = "Resume" if from_gameplay else "Close"
	
	for btn in [fullscreen_btn, main_menu_btn, close_btn]:
		btn.scale = Vector2.ONE
		
	_update_fullscreen_text()
	overlay.show()
	
	if from_gameplay:
		get_tree().paused = true

func close_menu() -> void:
	overlay.hide()
	is_in_gameplay = false
	get_tree().paused = false

func _on_main_menu_pressed() -> void:
	overlay.hide()
	get_tree().paused = false
	get_tree().change_scene_to_file(start_screen_scene)

func _on_fullscreen_pressed() -> void:
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_text()

func _update_fullscreen_text() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_full := (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	fullscreen_btn.text = "ON" if is_full else "OFF"

func _init_slider(slider: HSlider, bus_name: String) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("Không tìm thấy Audio Bus tên: " + bus_name)
		return
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(bus_idx, value <= 0.01)


func _create_square_grabber(fill_color: Color) -> ImageTexture:
	var w := 12
	var h := 14
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(TEXT_DARK_COLOR) # Viền pixel dày 2px màu #363956
	for x in range(2, w - 2):
		for y in range(2, h - 2):
			img.set_pixel(x, y, fill_color)
	return ImageTexture.create_from_image(img)

func _setup_button(btn: Button) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_color_override("font_color", TEXT_DARK_COLOR)
	btn.add_theme_color_override("font_hover_color", TEXT_DARK_COLOR)
	btn.add_theme_color_override("font_pressed_color", TEXT_DARK_COLOR)
	btn.add_theme_color_override("font_focus_color", TEXT_DARK_COLOR)
