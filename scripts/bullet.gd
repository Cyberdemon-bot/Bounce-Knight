extends Area2D

const SPEED = 150.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var is_reflected: bool = false

func _ready() -> void:
	add_to_group("enemy_bullets")
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if not is_reflected:
		if body.has_method("on_hit_by_dash"): 
			return
		if body.name == "Player" and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			queue_free()
			return
	else:
		if body.name == "Player":
			return
		if body.has_method("on_hit_by_dash"):
			body.on_hit_by_dash(direction * 400.0, damage)
			queue_free()
			return
			
	#queue_free()

func reflect(new_direction: Vector2) -> void:
	if is_reflected:
		return
	is_reflected = true
	remove_from_group("enemy_bullets")
	direction = new_direction.normalized()
	rotation = direction.angle()
	modulate = Color(0.3, 0.8, 1.0) 
	
	set_deferred("collision_mask", collision_mask | (1 << 2))
