extends Button

@export var hover_sfx: AudioStream
@export var click_sfx: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_visualfeedback.bind(true))
	mouse_exited.connect(_visualfeedback.bind(false))
	pressed.connect(SFXManager.play.bind(click_sfx))


func _visualfeedback(is_enter: bool) -> void:
	pivot_offset = size/2.0
	if (is_enter):
		SFXManager.play(hover_sfx)
		create_tween().tween_property(self, "scale", Vector2(1.1, 1.1) ,0.08)
	else:
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0) ,0.08)
