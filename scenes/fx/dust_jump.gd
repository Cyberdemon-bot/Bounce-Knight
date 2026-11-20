extends Node2D

@onready var dust: CPUParticles2D = $Dust

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if dust.one_shot:
		dust.emitting = true
		await dust.finished
		queue_free()
