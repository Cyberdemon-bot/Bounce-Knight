extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const AIR_ACCEL = 800.0

const DASH_SPEED = 500.0
const DASH_DURATION = 0.20
const DASH_COOLDOWN = 1.0
const DASH_BOUNCE_MULTIPLIER = 0.8

var is_bouncing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed and not event.echo:
		if dash_timer <= 0.0 and dash_cooldown_timer <= 0.0:
			dash()

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if dash_timer > 0.0:
		dash_timer -= delta
		var prev_velocity := velocity
		move_and_slide()
		
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
