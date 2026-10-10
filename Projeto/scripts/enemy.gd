extends CharacterBody2D
class_name Enemy

## Inimigo comum com IA simples: persegue o jogador quando esta
## dentro do alcance, ataca quando esta perto, reage a dano e morre.
## Aparencia (imagem/nome) e definida em runtime pela LevelManager de
## acordo com o personagem escolhido (CharacterData.enemy_texture),
## sem duplicar codigo por heroi.

signal died

@export var enemy_name: String = "Capanga"
@export var texture: Texture2D
@export var sprite_height: float = 46.0
@export var max_health: float = 40.0
@export var move_speed: float = 110.0
@export var damage: float = 8.0
@export var attack_range: float = 46.0
@export var chase_range: float = 340.0
@export var attack_cooldown: float = 1.3
@export var drop_chance: float = 0.3
@export var health_pack_scene: PackedScene

var depth_min: float = -1000.0
var depth_max: float = 1000.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Visuals/AttackPivot/Hitbox
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var shadow: Sprite2D = $Shadow

const SpriteUtil := preload("res://scripts/sprite_util.gd")

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var state: State = State.IDLE

var attack_timer: float = 0.0
var attack_active_timer: float = 0.0
var hurt_timer: float = 0.0
var target: Node2D

func _ready() -> void:
	add_to_group("enemy")
	health.setup(max_health)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	_refresh_visuals()
	call_deferred("_find_target")

func _refresh_visuals() -> void:
	SpriteUtil.fit(sprite, texture, sprite_height)

func configure(new_name: String, new_texture: Texture2D, new_height: float) -> void:
	enemy_name = new_name
	if new_texture:
		texture = new_texture
	sprite_height = new_height
	if is_inside_tree():
		_refresh_visuals()

func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0] as Node2D

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
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
			state = State.IDLE

	if state == State.HURT:
		velocity = Vector2.ZERO
	elif state == State.ATTACK:
		velocity = Vector2.ZERO
		attack_active_timer -= delta
		if attack_active_timer <= 0.0:
			hitbox.deactivate()
			state = State.CHASE
	else:
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range and attack_timer <= 0.0:
			_start_attack()
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

func _start_attack() -> void:
	state = State.ATTACK
	attack_timer = attack_cooldown
	attack_active_timer = 0.3
	hitbox.activate(damage)
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	# Vira o sprite (e a Hitbox, que fica dentro de Visuals) para o jogador.
	visuals.scale.x = dir * abs(visuals.scale.x)

func _on_hit_received(_amount: float, _knockback_x: float) -> void:
	if state == State.DEAD:
		return
	state = State.HURT
	hurt_timer = 0.22
	modulate = Color(1.0, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.22)

func _on_died() -> void:
	state = State.DEAD
	set_physics_process(false)
	
	# Desativa as áreas do inimigo para evitar novas colisões
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	# Chama o drop diferido para não instanciar o health pack no meio da consulta do Physics Server
	call_deferred("_try_drop_health_pack")
	
	died.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(visuals, "rotation", deg_to_rad(90.0), 0.4)
	tw.tween_callback(queue_free)

func _try_drop_health_pack() -> void:
	if health_pack_scene and randf() <= drop_chance and get_parent():
		var pack = health_pack_scene.instantiate()
		pack.global_position = global_position
		get_parent().add_child.call_deferred(pack)
