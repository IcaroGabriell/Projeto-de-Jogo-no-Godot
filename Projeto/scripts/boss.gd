extends CharacterBody2D
class_name Boss

signal died
signal health_updated(current: float, max_health: float)

@export var boss_name: String = "Chefao"
@export var texture: Texture2D
@export var sprite_height: float = 78.0
@export var max_health: float = 300.0
@export var move_speed: float = 95.0
@export var melee_damage: float = 14.0
@export var projectile_damage: float = 10.0
@export var attack_range: float = 54.0
@export var chase_range: float = 520.0
@export var attack_cooldown: float = 1.5

var depth_min: float = -1000.0
var depth_max: float = 1000.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Visuals/AttackPivot/Hitbox
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var name_label: Label = $NameLabel

const SpriteUtil := preload("res://scripts/sprite_util.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const PLAYER_HURTBOX_LAYER_BIT := 8

enum State { IDLE, CHASE, ATTACK_MELEE, ATTACK_RANGED, HURT, DEAD }
var state: State = State.IDLE

var target: Node2D
var attack_timer: float = 0.0
var attack_active_timer: float = 0.0
var hurt_timer: float = 0.0
var pattern_index: int = 0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	health.setup(max_health)
	health.died.connect(_on_died)
	health.health_changed.connect(func(c, m): health_updated.emit(c, m))
	hurtbox.hit_received.connect(_on_hit_received)
	_refresh_visuals()
	call_deferred("_find_target")

func _refresh_visuals() -> void:
	SpriteUtil.fit(sprite, texture, sprite_height)
	name_label.text = boss_name
	_update_name_position()

func configure(new_name: String, new_texture: Texture2D, new_height: float, new_max_health: float) -> void:
	boss_name = new_name
	if new_texture:
		texture = new_texture
	sprite_height = new_height
	max_health = new_max_health
	if is_inside_tree():
		health.setup(max_health)
		_refresh_visuals()

func _update_name_position() -> void:
	if not name_label:
		return
	var current_height: float = sprite_height * abs(visuals.scale.y)
	name_label.position.y = -current_height - 16.0

func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0] as Node2D

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_update_name_position()

	if not target:
		_find_target()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and state == State.HURT:
			state = State.CHASE

	match state:
		State.ATTACK_MELEE:
			velocity = Vector2.ZERO
			attack_active_timer -= delta
			if attack_active_timer <= 0.0:
				hitbox.deactivate()
				state = State.CHASE
		State.ATTACK_RANGED, State.HURT:
			velocity = Vector2.ZERO
		_:
			var dist := global_position.distance_to(target.global_position)
			if dist <= attack_range and attack_timer <= 0.0:
				_choose_attack(true)
			elif dist <= chase_range and attack_timer <= 0.0 and randf() < 0.006:
				_choose_attack(false)
			elif dist <= chase_range:
				state = State.CHASE
				var dir := (target.global_position - global_position).normalized()
				velocity = dir * move_speed
				if dir.x != 0.0:
					visuals.scale.x = (1.0 if dir.x >= 0.0 else -1.0) * abs(visuals.scale.x)
			else:
				state = State.IDLE
				velocity = Vector2.ZERO

	move_and_slide()
	position.y = clamp(position.y, depth_min, depth_max)
	z_index = int(position.y)

func _choose_attack(force_melee: bool) -> void:
	pattern_index = (pattern_index + 1) % 2
	if force_melee or pattern_index == 0:
		_start_melee()
	else:
		_start_ranged()

func _start_melee() -> void:
	state = State.ATTACK_MELEE
	attack_timer = attack_cooldown
	attack_active_timer = 0.35
	hitbox.activate(melee_damage)
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	visuals.scale.x = dir * abs(visuals.scale.x)

func _start_ranged() -> void:
	state = State.ATTACK_RANGED
	attack_timer = attack_cooldown
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	if get_parent():
		var proj = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(proj)
		proj.global_position = global_position + Vector2(22.0 * dir, -26.0)
		proj.setup(dir, projectile_damage, PLAYER_HURTBOX_LAYER_BIT)
	await get_tree().create_timer(0.35).timeout
	if state == State.ATTACK_RANGED:
		state = State.CHASE

func _on_hit_received(_amount: float, _knockback_x: float) -> void:
	if state == State.DEAD:
		return
	state = State.HURT
	hurt_timer = 0.2
	modulate = Color(1.0, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func _on_died() -> void:
	state = State.DEAD
	set_physics_process(false)
	died.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.parallel().tween_property(visuals, "rotation", deg_to_rad(90.0), 0.8)
