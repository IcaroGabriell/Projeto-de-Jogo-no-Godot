extends CharacterBody2D
class_name Player

## Controlador do jogador.
## Movimento em X (esquerda/direita) e Y (profundidade, simulando o
## eixo "para dentro da tela"). A ordenacao visual (quem desenha na
## frente de quem) e feita via z_index baseado na posicao Y atual,
## entao quanto mais "para baixo/perto da camera" o personagem estiver,
## mais na frente ele e desenhado.

signal health_updated(current: float, max_health: float)
signal died

@export var character_data: CharacterData

# Limites do corredor de profundidade (eixo Y). Configurados pela LevelManager.
var depth_min: float = -1000.0
var depth_max: float = 1000.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Visuals/AttackPivot/Hitbox
@onready var visuals: Node2D = $Visuals
@onready var body_polygon: Polygon2D = $Visuals/Body
@onready var head_polygon: Polygon2D = $Visuals/Head
@onready var weapon_polygon: Polygon2D = $Visuals/AttackPivot/WeaponFlash
@onready var shadow: Polygon2D = $Shadow
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite
@onready var name_label: Label = $NameLabel

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const ENEMY_HURTBOX_LAYER_BIT := 16 # camada 5 (EnemyHurtbox)

enum State { IDLE, WALK, JUMP, ATTACK, HURT, DEAD }
var state: State = State.IDLE

var facing: float = 1.0

var attack_cooldown_timer: float = 0.0
var attack_cooldown: float = 0.45
var attack_duration: float = 0.28
var attack_timer: float = 0.0

var ranged_cooldown_timer: float = 0.0
var ranged_cooldown: float = 0.6

var ranged_anim_timer: float = 0.0

var hurt_timer: float = 0.0
var hurt_duration: float = 0.3

var vertical_velocity: float = 0.0
var jump_height: float = 0.0
var gravity: float = 1500.0
var jump_force: float = 480.0
var is_jumping: bool = false

# Verdadeiro quando o heroi usa sprites animados (ex.: Kai) em vez dos poligonos.
var uses_sprite: bool = false

func _ready() -> void:
	add_to_group("player")
	if character_data:
		apply_character_data()
	_setup_sprite()
	health.died.connect(_on_died)
	health.health_changed.connect(func(c, m): health_updated.emit(c, m))
	hurtbox.hit_received.connect(_on_hit_received)
	weapon_polygon.visible = false

func apply_character_data() -> void:
	health.setup(character_data.max_health)
	body_polygon.color = character_data.body_color
	head_polygon.color = character_data.head_color
	weapon_polygon.color = character_data.accent_color
	name_label.text = character_data.character_name

func _setup_sprite() -> void:
	uses_sprite = false
	sprite.visible = false
	if character_data == null or not character_data.has_sprites():
		return
	var frames: SpriteFrames = character_data.build_sprite_frames()
	if frames == null:
		return
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = true
	sprite.offset = character_data.sprite_offset
	sprite.scale = Vector2.ONE * character_data.sprite_scale
	sprite.visible = true
	body_polygon.visible = false
	head_polygon.visible = false
	uses_sprite = true
	# Hurtbox mais alta para acompanhar o tamanho do sprite.
	var hurt_shape := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurt_shape and hurt_shape.shape is RectangleShape2D:
		var rect := (hurt_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(30, 62)
		hurt_shape.shape = rect
		hurt_shape.position = Vector2(0, -31)
	# Sombra um pouco maior, combinando com a base larga do personagem.
	var wide := PackedVector2Array()
	for pt in shadow.polygon:
		wide.append(Vector2(pt.x * 1.4, pt.y * 1.2))
	shadow.polygon = wide
	if frames.has_animation("idle"):
		sprite.play("idle")

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
	if ranged_anim_timer > 0.0:
		ranged_anim_timer -= delta
	if state == State.ATTACK:
		attack_timer -= delta
		if attack_timer <= 0.0:
			hitbox.deactivate()
			weapon_polygon.visible = false
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
		velocity *= 0.2 # levemente reduz movimento durante ataque

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
	shadow.scale = Vector2.ONE * clamp(1.0 - jump_height / 260.0, 0.45, 1.0)
	shadow.modulate.a = clamp(1.0 - jump_height / 260.0, 0.25, 0.55)

func _clamp_depth() -> void:
	position.y = clamp(position.y, depth_min, depth_max)

func _update_visual_order() -> void:
	z_index = int(position.y) + 1000 # sempre acima do cenario (z 0), mesmo com Y negativo

func _start_attack() -> void:
	state = State.ATTACK
	attack_timer = attack_duration
	attack_cooldown_timer = attack_cooldown
	var dmg: float = character_data.melee_damage if character_data else 12.0
	hitbox.activate(dmg)
	var base_x: float = abs(hitbox.position.x)
	hitbox.position.x = base_x * facing
	weapon_polygon.visible = not uses_sprite
	weapon_polygon.position.x = abs(weapon_polygon.position.x) * facing
	_play_sprite_once(_anim_or("kick", "punch"))

func _fire_projectile() -> void:
	if not get_parent():
		return
	ranged_cooldown_timer = ranged_cooldown
	if uses_sprite and state != State.ATTACK:
		ranged_anim_timer = 0.3
		_play_sprite_once(_anim_or("throw", "punch"))
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
	if uses_sprite and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	var tw := create_tween()
	tw.tween_property(visuals, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(visuals, "rotation", deg_to_rad(80.0) * facing, 0.6)
	died.emit()

## Usa a animacao preferida se o heroi tiver (ex.: Maya: kick/throw); senao, o fallback (punch).
func _anim_or(preferred: String, fallback: String) -> String:
	if uses_sprite and sprite.sprite_frames.has_animation(preferred):
		return preferred
	return fallback

func _play_sprite_once(anim: String) -> void:
	if not uses_sprite or not sprite.sprite_frames.has_animation(anim):
		return
	sprite.stop()
	sprite.animation = anim
	sprite.frame = 0
	sprite.play(anim)

func _update_sprite_animation() -> void:
	if not uses_sprite:
		return
	var wanted := "idle"
	match state:
		State.WALK:
			wanted = "walk"
		State.ATTACK:
			wanted = _anim_or("kick", "punch")
		State.JUMP:
			wanted = "jump"
		State.HURT, State.DEAD:
			wanted = "hurt"
	if ranged_anim_timer > 0.0 and (state == State.IDLE or state == State.WALK):
		wanted = _anim_or("throw", "punch")
	if sprite.sprite_frames.has_animation(wanted) and sprite.animation != wanted:
		sprite.play(wanted)

func _update_animation(delta: float) -> void:
	if uses_sprite:
		_update_sprite_animation()
		return
	match state:
		State.WALK:
			body_polygon.scale.y = 1.0 + sin(Time.get_ticks_msec() * 0.018) * 0.05
		State.ATTACK:
			body_polygon.scale.x = lerp(body_polygon.scale.x, 1.18, 20.0 * delta)
		_:
			body_polygon.scale.y = lerp(body_polygon.scale.y, 1.0, 8.0 * delta)
	if state != State.ATTACK:
		body_polygon.scale.x = lerp(body_polygon.scale.x, 1.0, 8.0 * delta)
