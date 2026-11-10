extends CharacterBody2D
class_name Boss

## Chefao de fase. Mesma logica base do Enemy, porem com mais vida,
## barra de vida visivel e dois tipos de ataque (corpo a corpo e
## projetil), alternados com uma pequena chance por frame.

signal died
signal health_updated(current: float, max_health: float)

@export var boss_name: String = "Chefao"
@export var body_color: Color = Color(0.5, 0.1, 0.5)
@export var head_color: Color = Color(0.75, 0.35, 0.75)
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
@onready var body_polygon: Polygon2D = $Visuals/Body
@onready var head_polygon: Polygon2D = $Visuals/Head
@onready var name_label: Label = $NameLabel
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const PLAYER_HURTBOX_LAYER_BIT := 8 # camada 4 (PlayerHurtbox)

enum State { IDLE, CHASE, ATTACK_MELEE, ATTACK_RANGED, HURT, DEAD }
var state: State = State.IDLE

var target: Node2D
var attack_timer: float = 0.0
var attack_active_timer: float = 0.0
var hurt_timer: float = 0.0
var pattern_index: int = 0

# Verdadeiro quando o chefao usa sprites animados em vez dos poligonos.
var uses_sprite: bool = false

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
	body_polygon.color = body_color
	head_polygon.color = head_color
	name_label.text = boss_name

func configure(new_name: String, new_body_color: Color, new_head_color: Color, new_max_health: float) -> void:
	boss_name = new_name
	body_color = new_body_color
	head_color = new_head_color
	max_health = new_max_health
	if is_inside_tree():
		health.setup(max_health)
		_refresh_visuals()

## Aplica o conjunto de sprites do chefao. Veja CharacterData.boss_sprite.
func configure_sprites(sprite_set: Dictionary, frame_size: Vector2i) -> void:
	var frames: SpriteFrames = CharacterData.make_sprite_frames(sprite_set.get("animations", {}), frame_size)
	if frames == null:
		return
	var sc: float = float(sprite_set.get("scale", 0.62))
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = true
	sprite.offset = sprite_set.get("offset", Vector2(0, -71))
	sprite.scale = Vector2.ONE * sc
	sprite.visible = true
	body_polygon.visible = false
	head_polygon.visible = false
	uses_sprite = true
	# Hurtbox acompanha a altura do sprite (conteudo do quadro: ~136 px).
	var h: float = 136.0 * sc
	var hurt_shape := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurt_shape and hurt_shape.shape is RectangleShape2D:
		var rect := (hurt_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(44, h)
		hurt_shape.shape = rect
		hurt_shape.position = Vector2(0, -h * 0.5)
	var shadow_node := get_node_or_null("Shadow") as Polygon2D
	if shadow_node:
		var wide := PackedVector2Array()
		for pt in shadow_node.polygon:
			wide.append(Vector2(pt.x * 1.25, pt.y * 1.1))
		shadow_node.polygon = wide
	if frames.has_animation("idle"):
		sprite.play("idle")

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
		State.CHASE:
			wanted = "walk" if velocity.length() > 1.0 else "idle"
		State.ATTACK_MELEE:
			wanted = "punch"
		State.ATTACK_RANGED:
			wanted = "throw" if sprite.sprite_frames.has_animation("throw") else "punch"
		State.HURT, State.DEAD:
			wanted = "hurt"
	if sprite.sprite_frames.has_animation(wanted) and sprite.animation != wanted:
		sprite.play(wanted)

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
	# +1000: mantem sempre positivo, acima do cenario (z 0), mesmo com Y negativo
	z_index = int(position.y) + 1000
	_update_sprite_animation()

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
	_play_sprite_once("punch")
	hitbox.activate(melee_damage)
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var base_x: float = abs(hitbox.position.x)
	hitbox.position.x = base_x * dir

func _start_ranged() -> void:
	state = State.ATTACK_RANGED
	attack_timer = attack_cooldown
	_play_sprite_once("throw" if uses_sprite and sprite.sprite_frames.has_animation("throw") else "punch")
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
	if uses_sprite and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	died.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.parallel().tween_property(visuals, "rotation", deg_to_rad(90.0), 0.8)
