extends CharacterBody2D

const SPEED = 100.0
const GROUND_ACCEL = 900.0
const GROUND_FRICTION = 1200.0
const AIR_ACCEL = 800.0
const AIR_FRICTION = 400.0
const JUMP_VELOCITY = -300.0

const FALL_GRAVITY_MULT = 1.5 # rớt nhanh

const DASH_SPEED = 350.0
const DASH_DURATION = 0.10
const DASH_COOLDOWN = 1.0
const DASH_BOUNCE_MULTIPLIER = 1.3

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
			var nudge := move_direction
			velocity.x = move_toward(velocity.x, 0.0, AIR_ACCEL * delta)
		elif move_direction:
			var is_turning := move_direction*velocity.x < 0.0
			var accel := GROUND_FRICTION if is_turning else GROUND_ACCEL
			velocity.x = move_toward(velocity.x, move_direction * SPEED, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
	elif not is_bouncing:
		if move_direction:
			velocity.x = move_toward(velocity.x, move_direction * SPEED, AIR_ACCEL * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, AIR_ACCEL * delta * 0.5)

func dash() -> void:
	var dash_dir := global_position.direction_to(get_global_mouse_position())
	if dash_dir.x != 0.0:
		$Sprite2D.flip_h = dash_dir.x < 0.0
	velocity = dash_dir * DASH_SPEED
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	VFXManager.spawn(VFXManager.DASH_EFFECT, body_point.global_position, dash_dir.angle())
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
		
	if invuln_timer > 0.0: invuln_timer -= delta
	
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
		var gravity_mult := 1.0
		if velocity.y > 0.0:
			gravity_mult = FALL_GRAVITY_MULT
		velocity += get_gravity() * delta * gravity_mult
			
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		VFXManager.spawn(VFXManager.DUST_JUMP, foot_point.global_position, 0.0, foot_point)
		jump_sound.pitch_scale = randf_range(0.95, 1.05)
		jump_sound.play()
			
	update_movement(delta)
	move_and_slide()
	
	if is_on_floor() and not was_on_floor:
		VFXManager.spawn(VFXManager.DUST_IMPACT, foot_point.global_position, 0.0, foot_point)
		land_sound.pitch_scale = randf_range(0.9, 1.1)
		land_sound.play()
	was_on_floor = is_on_floor()
	
	update_animation()
	update_skill_ui()
