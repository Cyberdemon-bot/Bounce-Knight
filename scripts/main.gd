extends Node2D

@export var enemy_scene: PackedScene
@export_file("*.tscn") var start_screen_scene: String = "res://scenes/start_screen_basic.tscn"

@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()
@onready var goal_area: Area2D = $GoalArea
@onready var win_layer: CanvasLayer = $WinLayer
@onready var restart_btn: Button = $WinLayer/PanelContainer/VBoxContainer/RestartButton
@onready var menu_btn: Button = $WinLayer/PanelContainer/VBoxContainer/MenuButton

var has_won: bool = false

func _ready() -> void:
	win_layer.visible = false
	goal_area.body_entered.connect(_on_goal_entered)
	
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	spawn_all_markers()

func _on_goal_entered(body: Node2D) -> void:
	if has_won:
		return
	if body.name == "Player":
		has_won = true
		win_layer.visible = true
		body.set_physics_process(false)

func _on_restart_pressed() -> void:
	get_tree().call_deferred("reload_current_scene")

func _on_menu_pressed() -> void:
	if start_screen_scene != "":
		get_tree().change_scene_to_file(start_screen_scene)

func spawn_all_markers() -> void:
	if enemy_scene == null:
		return
		
	for marker in spawn_points:
		if marker is Marker2D:
			var enemy := enemy_scene.instantiate()
			enemy.global_position = marker.global_position
			add_child(enemy)
