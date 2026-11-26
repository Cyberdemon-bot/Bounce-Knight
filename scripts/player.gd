extends CharacterBody2D

var speed: float
const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1200.0
const AIR_ACCEL = 800.0
const AIR_FRICTION = 400.0
var jump_velocity: float

const FALL_GRAVITY_MULT = 1.5 # rớt nhanh
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1 
const DASH_BOUNCE_GRACE = 0.05
const CORNER_CORRECTION_PX = 6

var dash_speed: float
const DASH_DURATION = 0.10
var dash_cooldown: float
var dash_bounce_mult: float

const BOUNCE_NUDGE_MAX = 400.0 # chuyển động ném xiên dịch chuyển tối đa ntn
const BOUNCE_NUDGE_MIN = 40.0 # tối thiểu
var bounce_ref_speed = dash_speed * dash_bounce_mult

var skill_cooldown = 1.0
var skill_force = dash_speed * 0.75
@onready var foot_point: Marker2D = $FootPoint
@onready var body_point: Marker2D = $BodyPoint
@onready var shield_area: Area2D = $ShieldPivot/Area2D
@onready var push_area: Area2D = $PushArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var dash_bar: TextureProgressBar = $%DashBar
@onready var push_bar: TextureProgressBar = $%PushBar
@onready var rune_label: Label = $HUD/RuneLabel
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var land_sound: AudioStreamPlayer2D = $LandSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var parry_sound: AudioStreamPlayer2D = $ParrySound
@onready var dash_cast: ShapeCast2D = $DashCast
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var bounce_line: Line2D = $BounceTrajectoryLine

var was_on_floor: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_jumping: bool = false
var is_bouncing: bool = false
var is_charging_dash: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var skill_cooldown_timer: float = 0.0

@export var max_hp: int = 5
var hp: int
var invuln_timer: float = 0.0 
var is_dead: bool = false
var spawn_position: Vector2
var _dash_fade_gradient: Gradient
func _ready() -> void:
	spawn_position = global_position
	max_hp = int(GameManager.stat(&"max_hp"))
	speed = GameManager.stat(&"speed")
	jump_velocity = GameManager.stat(&"jump_power")
	dash_speed = GameManager.stat(&"dash_speed")
	skill_force = dash_speed * 0.75
	dash_cooldown = 1.0
	dash_bounce_mult = GameManager.stat(&"dash_bounce_mult")
	bounce_ref_speed = maxf(dash_speed * dash_bounce_mult, 1.0)
	skill_cooldown = GameManager.stat(&"skill_cooldown")
	skill_force = dash_speed * 0.75
	
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp
	dash_bar.max_value = dash_cooldown
	dash_bar.value = dash_cooldown
	push_bar.max_value = skill_cooldown
	push_bar.value = skill_cooldown
	shield_area.area_entered.connect(_on_shield_area_entered)
	trajectory_line.top_level = true
	trajectory_line.visible = false
	bounce_line.top_level = true
	bounce_line.visible = false
	dash_cast.shape = $CollisionShape2D.shape
	dash_cast.position = $CollisionShape2D.position
	_dash_fade_gradient = trajectory_line.gradient
func update_skill_ui() -> void:
	if dash_cooldown_timer > 0.0:
		dash_bar.value = dash_cooldown - dash_cooldown_timer
	else:
		dash_bar.value = dash_cooldown

	if skill_cooldown_timer > 0.0:
		push_bar.value = skill_cooldown - skill_cooldown_timer
	else:
		push_bar.value = skill_cooldown

func _on_shield_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_bullets"):
		if area.has_method("reflect"):
			parry_sound.pitch_scale = randf_range(0.95, 1.05)
			parry_sound.play()
			var reflect_dir := global_position.direction_to(get_global_mouse_position())
			area.reflect(reflect_dir)

func take_damage(amount: int, hit_from: Vector2 = Vector2.ZERO) -> void:
	if invuln_timer > 0.0 or is_dead:
		return
	hit_sound.play()
	hp = max(hp - amount, 0)
	health_bar.value = hp
	invuln_timer = 0.8 
	is_charging_dash = false
	
	$Sprite2D.modulate = Color(1.0, 0.3, 0.3) 
	get_tree().create_timer(0.15).timeout.connect(func(): if is_instance_valid(self): $Sprite2D.modulate = Color.WHITE)
	
	if hit_from != Vector2.ZERO:
		var knockback_dir := hit_from.direction_to(global_position)
		velocity = (knockback_dir + Vector2(0, -0.3)).normalized() * 250.0
		is_bouncing = true
		
	if hp <= 0 and not is_dead:
		is_dead = true
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/upgrade_screen.tscn")

func _on_fall_out_of_bounds() -> void:
	if is_dead:
		return
	is_charging_dash = false
	velocity = Vector2.ZERO
	is_bouncing = false
	is_jumping = false
	global_position = spawn_position
	take_damage(1)

func update_animation() -> void:
	if not is_on_floor():
		if anim_player.current_animation != "jump":
			anim_player.play("jump")
	elif abs(velocity.x) > 10.0:
		if anim_player.current_animation != "run":
			anim_player.play("run")
	else:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")
			
func calculate_dash_bounce(incoming_vel: Vector2, collider: Object, hit_pos: Vector2, surface_normal: Vector2) -> Vector2:
	var normal := surface_normal
	if collider and collider.has_method("on_hit_by_dash"):
		normal = collider.global_position.direction_to(hit_pos)
	if normal == Vector2.ZERO:
		normal = -incoming_vel.normalized()
	
	if incoming_vel.dot(normal) < -10.0:
		return incoming_vel.bounce(normal) * dash_bounce_mult
	return Vector2.ZERO


func apply_gravity_step(current_vel: Vector2, delta: float) -> Vector2:
	var gravity_mult := FALL_GRAVITY_MULT if current_vel.y > 0.0 else 1.0
	return current_vel + get_gravity() * delta * gravity_mult

			
func update_dash_trajectory(mouse_pos: Vector2) -> void:
	var dash_dir := global_position.direction_to(mouse_pos)
	if dash_dir == Vector2.ZERO:
		trajectory_line.visible = false
		bounce_line.visible = false
		return

	trajectory_line.visible = true
	trajectory_line.clear_points()
	trajectory_line.add_point(global_position)

	bounce_line.visible = true
	bounce_line.clear_points()

	var shape_offset: Vector2 = $CollisionShape2D.position
	var max_dash_dist := dash_speed * DASH_DURATION
	var grace_dist := dash_speed * (DASH_DURATION + DASH_BOUNCE_GRACE)

	dash_cast.position = shape_offset
	dash_cast.target_position = dash_dir * grace_dist
	dash_cast.force_shapecast_update()

	if dash_cast.is_colliding():
		var safe_fraction := dash_cast.get_closest_collision_safe_fraction()
		var hit_pos := global_position + dash_cast.target_position * safe_fraction
		trajectory_line.add_point(hit_pos)

		var hit_normal := dash_cast.get_collision_normal(0)
		var bounce_vel := calculate_dash_bounce(
			dash_dir * dash_speed,
			dash_cast.get_collider(0),
			hit_pos,
			hit_normal
		)

		if bounce_vel != Vector2.ZERO:
			trajectory_line.gradient = null
			bounce_line.visible = true
			bounce_line.add_point(hit_pos)
			var push_out := hit_normal if hit_normal != Vector2.ZERO else -dash_dir
			var sim_pos := hit_pos + push_out * 1.0
			var dt := 0.03

			for i in range(18):
				bounce_vel = apply_gravity_step(bounce_vel, dt)
				var step_vec := bounce_vel * dt

				dash_cast.global_position = sim_pos + shape_offset
				dash_cast.target_position = step_vec
				dash_cast.force_shapecast_update()

				if dash_cast.is_colliding():
					var step_frac := dash_cast.get_closest_collision_safe_fraction()
					bounce_line.add_point(sim_pos + step_vec * step_frac)
					break

				sim_pos += step_vec
				bounce_line.add_point(sim_pos)
		else:
			trajectory_line.gradient = _dash_fade_gradient
	else:
		trajectory_line.gradient = _dash_fade_gradient
		trajectory_line.add_point(global_position + dash_dir * max_dash_dist)

	dash_cast.position = shape_offset



func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	$ShieldPivot.look_at(mouse_pos)
	$ShieldPivot/Sprite2D.flip_v = mouse_pos.x < global_position.x
	
	if is_charging_dash:
		$Sprite2D.flip_h = mouse_pos.x < global_position.x
		update_dash_trajectory(mouse_pos)
	else:
		trajectory_line.visible = false
		bounce_line.visible = false


	
func apply_corner_correction(delta: float) -> void:
	if velocity.y >= 0.0:
		return

	var up_step := Vector2(0.0, velocity.y * delta)
	if not test_move(global_transform, up_step):
		return

	for i in range(1, CORNER_CORRECTION_PX + 1):
		for dir in [1, -1]:
			var offset := Vector2(i * dir, 0.0)
			if not test_move(global_transform.translated(offset), up_step):
				global_position.x += offset.x
				return

func update_movement(delta: float) -> void:
	var move_direction := Input.get_axis("move_left", "move_right")
	
	if not is_charging_dash:
		if move_direction < 0.0:
			$Sprite2D.flip_h = true
		elif move_direction > 0.0:
			$Sprite2D.flip_h = false
		
	if is_on_floor():
		if is_bouncing:
			velocity.x = move_toward(velocity.x, 0.0, AIR_ACCEL * delta)
		elif move_direction:
			var is_turning := move_direction * velocity.x < 0.0
			var accel := GROUND_FRICTION if is_turning else GROUND_ACCEL
			velocity.x = move_toward(velocity.x, move_direction * speed, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
	elif not is_bouncing:
		if move_direction != 0.0:
			velocity.x = move_toward(velocity.x, move_direction * speed, AIR_ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, AIR_FRICTION * delta)
	elif move_direction != 0.0: # ng chs nhích quỹ đạo nếu velocity.x nhỏ
		var speed_ratio := clampf(abs(velocity.x) / bounce_ref_speed, 0.0, 1.0) 
		var nudge_accel := lerpf(BOUNCE_NUDGE_MAX, BOUNCE_NUDGE_MIN, speed_ratio)
		velocity.x += move_direction * nudge_accel * delta

func dash() -> void:
	var dash_dir := global_position.direction_to(get_global_mouse_position())
	if dash_dir.x != 0.0:
		$Sprite2D.flip_h = dash_dir.x < 0.0
	velocity = dash_dir * dash_speed
	dash_timer = DASH_DURATION
	dash_cooldown_timer = dash_cooldown
	VFXManager.spawn(VFXManager.DASH_EFFECT, body_point.global_position, dash_dir.angle())
	is_jumping = false
	is_bouncing = false

func push_nearby_enemies() -> void:
	skill_cooldown_timer = skill_cooldown
	for body in push_area.get_overlapping_bodies():
		if body.has_method("on_hit_by_dash"):
			var push_dir := global_position.direction_to(body.global_position)
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.UP
			push_dir = (push_dir + Vector2(0, -0.3)).normalized()
			body.on_hit_by_dash(push_dir * skill_force)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_Q:
			if event.pressed and dash_timer <= 0.0 and dash_cooldown_timer <= 0.0:
				is_charging_dash = true
			elif not event.pressed and is_charging_dash:
				is_charging_dash = false
				dash()
		elif event.keycode == KEY_E and event.pressed and skill_cooldown_timer <= 0.0:
			push_nearby_enemies()


func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if skill_cooldown_timer > 0.0:
		skill_cooldown_timer -= delta
	if invuln_timer > 0.0:
		invuln_timer -= delta

	# Ghi nhận jump buffer ở đây để không bị bỏ sót khi đang dash
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
	
	if dash_timer > 0.0:
		dash_timer -= delta
		var prev_velocity := velocity
		move_and_slide()
		
		for body in shield_area.get_overlapping_bodies():
			if body.has_method("on_hit_by_dash"):
				var hit_dir := global_position.direction_to(body.global_position)
				body.on_hit_by_dash(hit_dir * dash_speed)
				
				velocity = calculate_dash_bounce(prev_velocity, body, global_position, Vector2.ZERO)
				dash_timer = 0.0
				is_bouncing = true
				dash_cooldown_timer = 0.0
				return

		var did_bounce := false
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var bounce_vel := calculate_dash_bounce(prev_velocity, collision.get_collider(), global_position, collision.get_normal())
			if bounce_vel != Vector2.ZERO:
				velocity = bounce_vel
				dash_timer = 0.0
				is_bouncing = true
				did_bounce = true
				break
				
		if not did_bounce and dash_timer <= 0.0: # cho ng chs bounce nếu gần tường mà k chạm 
			var grace_hit := move_and_collide(prev_velocity * DASH_BOUNCE_GRACE, true)
			if grace_hit and prev_velocity.dot(grace_hit.get_normal()) < -10.0:
				global_position += grace_hit.get_travel()
				velocity = prev_velocity.bounce(grace_hit.get_normal()) * dash_bounce_mult
				is_bouncing = true
			else:
				velocity *= 0.4
		return
		
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		if velocity.y >= 0.0:
			is_jumping = false
			if abs(velocity.x) <= speed:
				is_bouncing = false
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		if velocity.y > 0.0:
			is_jumping = false
		velocity = apply_gravity_step(velocity, delta)

	# Thực hiện nhảy khi có buffer và còn coyote time
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		is_jumping = true
		VFXManager.spawn(VFXManager.DUST_JUMP, foot_point.global_position, 0.0, foot_point)
		jump_sound.pitch_scale = randf_range(0.95, 1.05)
		jump_sound.play()
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		
		# Xử lý trường hợp bấm và thả phím nhảy quá nhanh trước khi chạm đất
		if not Input.is_action_pressed("jump"):
			velocity.y *= 0.2
			is_jumping = false

	if Input.is_action_just_released("jump") and is_jumping: # nhảy ngắn
		velocity.y *= 0.2
		is_jumping = false
		
	update_movement(delta)
	apply_corner_correction(delta)
	move_and_slide()
	
	if is_on_floor() and not was_on_floor:
		VFXManager.spawn(VFXManager.DUST_IMPACT, foot_point.global_position, 0.0, foot_point)
		land_sound.pitch_scale = randf_range(0.9, 1.1)
		land_sound.play()
	was_on_floor = is_on_floor()
	
	update_animation()
	update_skill_ui()
