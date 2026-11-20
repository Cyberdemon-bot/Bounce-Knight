extends Node2D

@onready var streaks: CPUParticles2D = $Streaks

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	streaks.emitting = true
	await get_tree().create_timer(0.1).timeout
	streaks.emitting = false
	await get_tree().create_timer(streaks.lifetime).timeout
	queue_free()
