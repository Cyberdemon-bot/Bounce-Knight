extends Node

func play(stream: AudioStream, pitch_variance: float = 0.05, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
