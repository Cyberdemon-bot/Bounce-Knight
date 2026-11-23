extends CharacterBody2D

const FRICTION = 900.0
const BOUNCE_DAMPING = 0.6
const SEPARATION_FORCE = 450.0

@export var max_hp: int = 3
@export var attack_interval: float = 2.0
@export var attack_range: float = 350.0 
@export var damage: int = 1 
@export var bullet_scene: PackedScene
@export var rune_scene: PackedScene
@export var rune_drop_count: int = 15

@onready var separation_area: Area2D = $SeparationArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var health_bar: ProgressBar = $HealthBar
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

var hp: int
var hit_cooldown: float = 0.0
var attack_timer: float = 0.0
var is_attacking: bool = false
var default_muzzle_x: float

func _ready() -> void:
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.visible = false
	
	attack_timer = attack_interval
	default_muzzle_x = abs(muzzle.position.x)
	if anim_player.has_animation("idle"):
		anim_player.play("idle")

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
				
	if not is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			var player := get_player()
			if player != null and global_position.distance_to(player.global_position) <= attack_range:
				face_player(player)
				perform_attack()
			else:
				attack_timer = 0.2

func get_player() -> Node2D:
	return get_tree().current_scene.get_node_or_null("Player")

func face_player(player: Node2D) -> void:
	var is_player_on_left := player.global_position.x < global_position.x
	sprite.flip_h = not is_player_on_left
	muzzle.position.x = -default_muzzle_x if is_player_on_left else default_muzzle_x

func perform_attack() -> void:
	is_attacking = true
	attack_timer = attack_interval
	
	if anim_player.has_animation("attack"):
		anim_player.play("attack")
		shoot_at_player()
		await anim_player.animation_finished
	else:
		shoot_at_player()
		
	is_attacking = false
	if anim_player.has_animation("idle"):
		anim_player.play("idle")

func shoot_at_player() -> void:
	if bullet_scene == null:
		return
		
	var player := get_player()
	if player == null:
		return
		
	face_player(player)
	
	shoot_sound.pitch_scale = randf_range(0.95, 1.05)
	shoot_sound.play()
	
	var bullet := bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = muzzle.global_position.direction_to(player.global_position)
	bullet.rotation = bullet.direction.angle()
	if "damage" in bullet:
		bullet.damage = damage
	
	get_tree().current_scene.add_child(bullet)

func apply_soft_separation(delta: float) -> void:
	for body in separation_area.get_overlapping_bodies():
		if body == self:
			continue
		var push_dir := body.global_position.direction_to(global_position)
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.RIGHT if get_instance_id() > body.get_instance_id() else Vector2.LEFT
		velocity.x += push_dir.x * SEPARATION_FORCE * delta

func on_hit_by_dash(impulse: Vector2, incoming_damage: int = 1) -> void:
	if hit_cooldown > 0.0:
		return
	hit_cooldown = 0.25
	velocity = impulse
	take_damage(incoming_damage)

func take_damage(amount: int) -> void:
	hp -= amount
	health_bar.visible = true
	health_bar.value = hp
	
	hit_sound.pitch_scale = randf_range(0.9, 1.1)
	hit_sound.play()
	
	modulate = Color(1.0, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(func(): if is_instance_valid(self): modulate = Color.WHITE)
	
	if hp <= 0:
		spawn_runes()
		hit_sound.reparent(get_tree().current_scene)
		hit_sound.finished.connect(hit_sound.queue_free)
		call_deferred("queue_free")

func spawn_runes() -> void:
	if rune_scene == null:
		return
	for i in rune_drop_count:
		var rune := rune_scene.instantiate()
		rune.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", rune)
