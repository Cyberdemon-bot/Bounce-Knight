extends Area2D

@export var value: int = 1
const MAGNET_RANGE = 70.0
const MOVE_SPEED = 220.0

var velocity: Vector2 = Vector2.ZERO
var is_grounded: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	velocity = Vector2(randf_range(-80.0, 80.0), randf_range(-160.0, -100.0))

func _physics_process(delta: float) -> void:
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player != null and global_position.distance_to(player.global_position) <= MAGNET_RANGE:
		is_grounded = false
		var dir := global_position.direction_to(player.global_position)
		global_position += dir * MOVE_SPEED * delta
		return

	if not is_grounded:
		velocity.y = min(velocity.y + 400.0 * delta, 250.0)
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		
		var next_pos := global_position + velocity * delta
		if velocity.y > 0.0:
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsRayQueryParameters2D.create(global_position, next_pos + Vector2(0, 4), 1)
			var result := space_state.intersect_ray(query)
			if result:
				global_position = result.position - Vector2(0, 4)
				velocity = Vector2.ZERO
				is_grounded = true
				return
				
		global_position = next_pos

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameManager.add_runes(value)
		queue_free()
