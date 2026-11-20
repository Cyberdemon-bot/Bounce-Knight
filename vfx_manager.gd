extends Node

const DUST_JUMP = preload("res://scenes/fx/dust_jump.tscn")
const DUST_IMPACT = preload("res://scenes/fx/dust_impact.tscn")
const DASH_EFFECT = preload("res://scenes/fx/dash_effect.tscn")
func spawn(scene: PackedScene, pos: Vector2, rot: float = 0.0, parent: Node = null) -> void:
	var vfx := scene.instantiate()
	var target := parent if parent else get_tree().current_scene
	target.add_child(vfx)
	vfx.global_position = pos
	vfx.rotation = rot
