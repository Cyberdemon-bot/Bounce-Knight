extends CharacterBody2D

const SPEED = 100.0
const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1200.0
const AIR_ACCEL = 800.0
const AIR_FRICTION = 400.0
const JUMP_VELOCITY = -270.0

const FALL_GRAVITY_MULT = 1.5 # rớt nhanh
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1 
const DASH_BOUNCE_GRACE = 0.025

const DASH_SPEED = 350.0
const DASH_DURATION = 0.10
const DASH_COOLDOWN = 1.0
const DASH_BOUNCE_MULTIPLIER = 1.3

const BOUNCE_NUDGE_MAX = 400.0 # chuyển động ném xiên dịch chuyển tối đa ntn
const BOUNCE_NUDGE_MIN = 40.0 # tối thiểu
const BOUNCE_REF_SPEED = DASH_SPEED * DASH_BOUNCE_MULTIPLIER

const PUSH_COOLDOWN = 1.5
const PUSH_FORCE = DASH_SPEED * 0.75
@onready var foot_point: Marker2D = $FootPoint
@onready var body_point: Marker2D = $BodyPoint
@onready var shield_area: Area2D = $ShieldPivot/Area2D
@onready var push_area: Area2D = $PushArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var dash_bar: ProgressBar = $HUD/SkillBar/DashBar
@onready var push_bar: ProgressBar = $HUD/SkillBar/PushBar
@onready var rune_label: Label = $HUD/RuneLabel
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var land_sound: AudioStreamPlayer2D = $LandSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var parry_sound: AudioStreamPlayer2D = $ParrySound

var was_on_floor: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_jumping: bool = false
var is_bouncing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var push_cooldown_timer: float = 0.0

@export var max_hp: int = 5
var hp: int
var invuln_timer: float = 0.0 

func _ready() -> void:
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp
	dash_bar.max_value = DASH_COOLDOWN
	dash_bar.value = DASH_COOLDOWN
	push_bar.max_value = PUSH_COOLDOWN
	push_bar.value = PUSH_COOLDOWN
	shield_area.area_entered.connect(_on_shield_area_entered)
	
func update_skill_ui() -> void:
	if dash_cooldown_timer > 0.0:
		dash_bar.value = DASH_COOLDOWN - dash_cooldown_timer
		dash_bar.modulate = Color(0.6, 0.6, 0.6) 
	else:
		dash_bar.value = DASH_COOLDOWN
		dash_bar.modulate = Color.WHITE 

	if push_cooldown_timer > 0.0:
		push_bar.value = PUSH_COOLDOWN - push_cooldown_timer
		push_bar.modulate = Color(0.6, 0.6, 0.6)
	else:
		push_bar.value = PUSH_COOLDOWN
		push_bar.modulate = Color.WHITE

func _on_shield_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_bullets"):
		if area.has_method("reflect"):
			parry_sound.pitch_scale = randf_range(0.95, 1.05)
			parry_sound.play()
			var reflect_dir := global_position.direction_to(get_global_mouse_position())
			area.reflect(reflect_dir)

func take_damage(amount: int, hit_from: Vector2 = Vector2.ZERO) -> void:
	if invuln_timer > 0.0:
		return
	hit_sound.play()
	hp = max(hp - amount, 0)
	health_bar.value = hp
	invuln_timer = 0.8 
	
	$Sprite2D.modulate = Color(1.0, 0.3, 0.3) 
	get_tree().create_timer(0.15).timeout.connect(func(): if is_instance_valid(self): $Sprite2D.modulate = Color.WHITE)
	
	if hit_from != Vector2.ZERO:
		var knockback_dir := hit_from.direction_to(global_position)
		velocity = (knockback_dir + Vector2(0, -0.3)).normalized() * 250.0
		is_bouncing = true
		
	if hp <= 0:
		get_tree().call_deferred("reload_current_scene")


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


func _process(_delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	$ShieldPivot.look_at(mouse_pos)
	$ShieldPivot/Sprite2D.flip_v = mouse_pos.x < global_position.x

func update_movement(delta: float) -> void:
	var move_direction := Input.get_axis("move_left", "move_right")
	
	if move_direction < 0.0:
		$Sprite2D.flip_h = true
	elif move_direction > 0.0:
		$Sprite2D.flip_h = false
		
	if is_on_floor():
		if is_bouncing:
			velocity.x = move_toward(velocity.x, 0.0, AIR_ACCEL * delta)
		elif move_direction:
			var is_turning := move_direction*velocity.x < 0.0
			var accel := GROUND_FRICTION if is_turning else GROUND_ACCEL
			velocity.x = move_toward(velocity.x, move_direction * SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
	elif not is_bouncing:
		if move_direction != 0.0:
			velocity.x = move_toward(velocity.x, move_direction * SPEED, AIR_ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, AIR_FRICTION * delta)
	elif move_direction != 0.0: # ng chs nhích quỹ đạo nếu velocity.x nhỏ
		var speed_ratio := clampf(abs(velocity.x) / BOUNCE_REF_SPEED, 0.0, 1.0) 
		var nudge_accel := lerpf(BOUNCE_NUDGE_MAX, BOUNCE_NUDGE_MIN, speed_ratio)
		velocity.x += move_direction * nudge_accel * delta

func dash() -> void:
	var dash_dir := global_position.direction_to(get_global_mouse_position())
	if dash_dir.x != 0.0:
		$Sprite2D.flip_h = dash_dir.x < 0.0
	velocity = dash_dir * DASH_SPEED
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	VFXManager.spawn(VFXManager.DASH_EFFECT, body_point.global_position, dash_dir.angle())
	is_jumping = false
	is_bouncing = false

func push_nearby_enemies() -> void:
	push_cooldown_timer = PUSH_COOLDOWN
	for body in push_area.get_overlapping_bodies():
		if body.has_method("on_hit_by_dash"):
			var push_dir := global_position.direction_to(body.global_position)
			if push_dir == Vector2.ZERO:
				push_dir = Vector2.UP
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
				
		if not did_bounce and dash_timer <= 0.0: # cho ng chs bounce nếu gần tường mà k chạm 
			var grace_hit := move_and_collide(prev_velocity * DASH_BOUNCE_GRACE, true)
			if grace_hit and prev_velocity.dot(grace_hit.get_normal()) < -10.0:
				global_position += grace_hit.get_travel()
				velocity = prev_velocity.bounce(grace_hit.get_normal()) * DASH_BOUNCE_MULTIPLIER
				is_bouncing = true
			else:
				velocity *= 0.4
		return
		
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		if velocity.y >= 0.0:
			is_jumping = false
			if abs(velocity.x) <= SPEED:
				is_bouncing = false
	else:
		var gravity_mult := 1.0
		coyote_timer = max(coyote_timer - delta, 0.0)
		if velocity.y > 0.0:
			is_jumping = false
			gravity_mult = FALL_GRAVITY_MULT
		velocity += get_gravity() * delta * gravity_mult

	# Thực hiện nhảy khi có buffer và còn coyote time
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
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
	move_and_slide()
	
	if is_on_floor() and not was_on_floor:
		VFXManager.spawn(VFXManager.DUST_IMPACT, foot_point.global_position, 0.0, foot_point)
		land_sound.pitch_scale = randf_range(0.9, 1.1)
		land_sound.play()
	was_on_floor = is_on_floor()
	
	update_animation()
	update_skill_ui()
