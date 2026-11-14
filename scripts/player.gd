extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -350.0
const AIR_ACCEL = 800.0

const DASH_SPEED = 600.0
const DASH_DURATION = 0.20
const DASH_COOLDOWN = 1.0
const DASH_BOUNCE_MULTIPLIER = 0.8

const PUSH_COOLDOWN = 1.5
const PUSH_FORCE = DASH_SPEED * 0.75

@onready var shield_area: Area2D = $ShieldPivot/Area2D
@onready var push_area: Area2D = $PushArea

var is_bouncing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var push_cooldown_timer: float = 0.0

func _process(_delta: float) -> void:
	$ShieldPivot.look_at(get_global_mouse_position())

func update_movement(delta: float) -> void:
	var move_direction := Input.get_axis("move_left", "move_right")
	if is_on_floor():
		if is_bouncing:
			velocity.x = move_toward(velocity.x, 0, AIR_ACCEL * delta)
		elif move_direction:
			velocity.x = move_direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	elif not is_bouncing:
		if move_direction:
			velocity.x = move_toward(velocity.x, move_direction * SPEED, AIR_ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, AIR_ACCEL * delta * 0.5)

func dash() -> void:
	var dash_dir := global_position.direction_to(get_global_mouse_position())
	velocity = dash_dir * DASH_SPEED
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	is_bouncing = false

func push_nearby_enemies() -> void:
	push_cooldown_timer = PUSH_COOLDOWN
	for body in push_area.get_overlapping_bodies():
		if body.has_method("on_hit_by_dash"):
			var push_dir := global_position.direction_to(body.global_position)
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.UP
			# Nhích nhẹ góc hất lên trên (y - 0.3) để quái nhấc khỏi mặt đất và văng mượt hơn
			push_dir = (push_dir + Vector2(0, -0.3)).normalized()
			body.on_hit_by_dash(push_dir * PUSH_FORCE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q and dash_timer <= 0.0 and dash_cooldown_timer <= 0.0:
			dash()
		elif event.keycode == KEY_E and push_cooldown_timer <= 0.0:
			push_nearby_enemies()

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if push_cooldown_timer > 0.0:
		push_cooldown_timer -= delta

	if dash_timer > 0.0:
		dash_timer -= delta
		var prev_velocity := velocity
		move_and_slide()
		
		for body in shield_area.get_overlapping_bodies():
			if body.has_method("on_hit_by_dash"):
				var hit_dir := global_position.direction_to(body.global_position)
				body.on_hit_by_dash(hit_dir * DASH_SPEED)
				
				var bounce_normal := body.global_position.direction_to(global_position)
				velocity = prev_velocity.bounce(bounce_normal) * DASH_BOUNCE_MULTIPLIER
				dash_timer = 0.0
				is_bouncing = true
				dash_cooldown_timer = 0.0
				return

		var did_bounce := false
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var normal := collision.get_normal()
			if prev_velocity.dot(normal) < -10.0:
				velocity = prev_velocity.bounce(normal) * DASH_BOUNCE_MULTIPLIER
				dash_timer = 0.0
				is_bouncing = true
				did_bounce = true
				break
				
		if not did_bounce and dash_timer <= 0.0:
			velocity *= 0.4
		return
		
	if is_on_floor():
		if abs(velocity.x) <= SPEED:
			is_bouncing = false
	else:
		velocity += get_gravity() * delta
			
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
			
	update_movement(delta)
	move_and_slide()
