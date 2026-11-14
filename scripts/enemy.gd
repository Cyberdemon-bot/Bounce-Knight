extends CharacterBody2D

const FRICTION = 900.0
const BOUNCE_DAMPING = 0.6
const SEPARATION_FORCE = 450.0

@onready var separation_area: Area2D = $SeparationArea

var hit_cooldown: float = 0.0

func _physics_process(delta: float) -> void:
	if hit_cooldown > 0.0:
		hit_cooldown -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	apply_soft_separation(delta)
		
	var prev_velocity := velocity
	move_and_slide()
	
	if prev_velocity.length() > 300.0 and get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var normal := get_slide_collision(i).get_normal()
			if prev_velocity.dot(normal) < -10.0:
				velocity = prev_velocity.bounce(normal) * BOUNCE_DAMPING
				break

func apply_soft_separation(delta: float) -> void:
	for body in separation_area.get_overlapping_bodies():
		if body == self:
			continue
		var push_dir := body.global_position.direction_to(global_position)
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.RIGHT if get_instance_id() > body.get_instance_id() else Vector2.LEFT
		velocity.x += push_dir.x * SEPARATION_FORCE * delta

func on_hit_by_dash(impulse: Vector2) -> void:
	if hit_cooldown > 0.0:
		return
	hit_cooldown = 0.25
	velocity = impulse
