extends Node2D

@export var enemy_scene: PackedScene

@onready var spawn_points: Array[Node] = $SpawnPoints.get_children()

func _ready() -> void:
	spawn_all_markers()

func spawn_all_markers() -> void:
	if enemy_scene == null:
		return
		
	for marker in spawn_points:
		if marker is Marker2D:
			var enemy := enemy_scene.instantiate()
			enemy.global_position = marker.global_position
			add_child(enemy)
