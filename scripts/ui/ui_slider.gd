extends HSlider

@export var slider_sfx: AudioStream
@export var sfx_cooldown_ms: int = 60

var _last_sfx_time: int = 0

func _ready() -> void:
	value_changed.connect(_on_value_changed)

func _on_value_changed(_value: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_sfx_time >= sfx_cooldown_ms:
		_last_sfx_time = now
		SFXManager.play(slider_sfx)
