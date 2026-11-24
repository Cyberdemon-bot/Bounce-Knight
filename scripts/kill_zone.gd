extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("_on_fall_out_of_bounds"):
		body._on_fall_out_of_bounds()
