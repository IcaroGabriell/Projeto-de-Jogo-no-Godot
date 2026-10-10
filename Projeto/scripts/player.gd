extends CharacterBody2D
class_name Player

signal health_updated(current: float, max_health: float)
signal died

@export var character_data: CharacterData

var depth_min: float = -1000.0
var depth_max: float = 1000.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Visuals/AttackPivot/Hitbox
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var weapon_sprite: Sprite2D = $Visuals/AttackPivot/WeaponFlash
@onready var shadow: Sprite2D = $Shadow
@onready var name_label: Label = $NameLabel

const SpriteUtil := preload("res://scripts/sprite_util.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ENEMY_HURTBOX_LAYER_BIT := 16

enum State { IDLE, WALK, JUMP, ATTACK, HURT, DEAD }
var state: State = State.IDLE

var facing: float = 1.0

var attack_cooldown_timer: float = 0.0
var attack_cooldown: float = 0.45
var attack_duration: float = 0.28
var attack_timer: float = 0.0

var ranged_cooldown_timer: float = 0.0
var ranged_cooldown: float = 0.6

var hurt_timer: float = 0.0
var hurt_duration: float = 0.3

var vertical_velocity: float = 0.0
var jump_height: float = 0.0
var gravity: float = 1500.0
var jump_force: float = 480.0
var is_jumping: bool = false

var _sprite_base_scale: Vector2 = Vector2.ONE
var _shadow_base_scale: Vector2 = Vector2.ONE
var _anim_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("player")
	_shadow_base_scale = shadow.scale
	_sprite_base_scale = SpriteUtil.fit(sprite, null, 0.0)
	if character_data:
		apply_character_data()
	health.died.connect(_on_died)
	health.health_changed.connect(func(c, m): health_updated.emit(c, m))
	hurtbox.hit_received.connect(_on_hit_received)
	weapon_sprite.visible = false

func apply_character_data() -> void:
	health.setup(character_data.max_health)
	_sprite_base_scale = SpriteUtil.fit(sprite, character_data.texture, character_data.sprite_height)
	weapon_sprite.modulate = character_data.accent_color
	name_label.text = character_data.character_name
	_update_name_position()

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_tick_timers(delta)
	if state != State.HURT:
		_handle_input(delta)
	else:
		velocity = Vector2.ZERO
	_apply_jump(delta)
	move_and_slide()
	_clamp_depth()
	_update_visual_order()
	_update_animation(delta)

func _tick_timers(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if ranged_cooldown_timer > 0.0:
		ranged_cooldown_timer -= delta
	if state == State.ATTACK:
		attack_timer -= delta
		if attack_timer <= 0.0:
			hitbox.deactivate()
			weapon_sprite.visible = false
			state = State.IDLE
	if state == State.HURT:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			state = State.IDLE

func _handle_input(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	var speed: float = character_data.move_speed if character_data else 220.0
	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * speed
	else:
		velocity = Vector2.ZERO

	if input_dir.x != 0.0:
		facing = sign(input_dir.x)
		var s: float = abs(visuals.scale.x)
		visuals.scale.x = facing * s

	if state == State.ATTACK:
		velocity *= 0.2

	if Input.is_action_just_pressed("jump") and not is_jumping:
		is_jumping = true
		vertical_velocity = jump_force
		state = State.JUMP

	if Input.is_action_just_pressed("attack_melee") and attack_cooldown_timer <= 0.0 and state != State.ATTACK:
		_start_attack()

	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer <= 0.0:
		_fire_projectile()

	if state != State.ATTACK and state != State.JUMP:
		if input_dir != Vector2.ZERO:
			state = State.WALK
		else:
			state = State.IDLE

func _apply_jump(delta: float) -> void:
	if is_jumping:
		jump_height += vertical_velocity * delta
		vertical_velocity -= gravity * delta
		if jump_height <= 0.0:
			jump_height = 0.0
			is_jumping = false
			vertical_velocity = 0.0
			if state == State.JUMP:
				state = State.IDLE
	visuals.position.y = -jump_height
	_update_name_position()
	shadow.scale = _shadow_base_scale * clamp(1.0 - jump_height / 260.0, 0.45, 1.0)
	shadow.modulate.a = clamp(1.0 - jump_height / 260.0, 0.25, 0.55)

func _update_name_position() -> void:
	var base_height: float = character_data.sprite_height if character_data else 52.0
	name_label.position.y = -base_height - 14.0 - jump_height

func _clamp_depth() -> void:
	position.y = clamp(position.y, depth_min, depth_max)

func _update_visual_order() -> void:
	z_index = int(position.y)

func _start_attack() -> void:
	state = State.ATTACK
	attack_timer = attack_duration
	attack_cooldown_timer = attack_cooldown
	var dmg: float = character_data.melee_damage if character_data else 12.0
	hitbox.activate(dmg)
	weapon_sprite.visible = true

func _fire_projectile() -> void:
	if not get_parent():
		return
	ranged_cooldown_timer = ranged_cooldown
	var proj = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(20.0 * facing, -jump_height - 26.0)
	var dmg: float = character_data.projectile_damage if character_data else 8.0
	proj.setup(facing, dmg, ENEMY_HURTBOX_LAYER_BIT)

func _on_hit_received(_amount: float, _knockback_x: float) -> void:
	if state == State.DEAD:
		return
	state = State.HURT
	hurt_timer = hurt_duration
	modulate = Color(1.0, 0.45, 0.45)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1), hurt_duration)

func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(visuals, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(visuals, "rotation", deg_to_rad(80.0) * facing, 0.6)
	died.emit()

func _update_animation(delta: float) -> void:
	match state:
		State.WALK:
			_anim_scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.018) * 0.05
		State.ATTACK:
			_anim_scale.x = lerp(_anim_scale.x, 1.18, 20.0 * delta)
		_:
			_anim_scale.y = lerp(_anim_scale.y, 1.0, 8.0 * delta)
	if state != State.ATTACK:
		_anim_scale.x = lerp(_anim_scale.x, 1.0, 8.0 * delta)
	sprite.scale = _sprite_base_scale * _anim_scale
