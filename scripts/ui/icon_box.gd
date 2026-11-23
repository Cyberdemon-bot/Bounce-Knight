extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(_visualfeedback.bind(true))
	mouse_exited.connect(_visualfeedback.bind(false))

func _visualfeedback(is_enter: bool) -> void:
	pivot_offset = size/2.0
	if (is_enter):
		create_tween().tween_property(self, "scale", Vector2(1.1, 1.1) ,0.08)
	else:
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0) ,0.08)
