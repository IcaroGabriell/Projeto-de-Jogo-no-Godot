extends CharacterBody2D
class_name Enemy

## Inimigo comum com IA simples: persegue o jogador quando esta
## dentro do alcance, ataca quando esta perto, reage a dano e morre.
## Aparencia (cor/nome) e definida em runtime pela LevelManager de
## acordo com o personagem escolhido, sem duplicar codigo por heroi.

signal died

@export var enemy_name: String = "Capanga"
@export var body_color: Color = Color(0.25, 0.3, 0.55)
@export var head_color: Color = Color(0.5, 0.55, 0.75)
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
@onready var body_polygon: Polygon2D = $Visuals/Body
@onready var head_polygon: Polygon2D = $Visuals/Head
@onready var shadow: Polygon2D = $Shadow
@onready var sprite: AnimatedSprite2D = $Visuals/Sprite

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var state: State = State.IDLE

var attack_timer: float = 0.0
var attack_active_timer: float = 0.0
var hurt_timer: float = 0.0
var target: Node2D

# Verdadeiro quando o capanga usa sprites animados em vez dos poligonos.
var uses_sprite: bool = false

func _ready() -> void:
	add_to_group("enemy")
	health.setup(max_health)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	_refresh_visuals()
	call_deferred("_find_target")

func _refresh_visuals() -> void:
	body_polygon.color = body_color
	head_polygon.color = head_color

func configure(new_name: String, new_body_color: Color, new_head_color: Color) -> void:
	enemy_name = new_name
	body_color = new_body_color
	head_color = new_head_color
	if is_inside_tree():
		_refresh_visuals()

## Aplica um conjunto de sprites (um capanga sorteado). Veja CharacterData.enemy_sprite_sets.
func configure_sprites(sprite_set: Dictionary, frame_size: Vector2i) -> void:
	var frames: SpriteFrames = CharacterData.make_sprite_frames(sprite_set.get("animations", {}), frame_size)
	if frames == null:
		return
	enemy_name = str(sprite_set.get("name", enemy_name))
	var sc: float = float(sprite_set.get("scale", 0.45))
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = true
	sprite.offset = sprite_set.get("offset", Vector2(0, -69))
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
		rect.size = Vector2(30, h)
		hurt_shape.shape = rect
		hurt_shape.position = Vector2(0, -h * 0.5)
	# Sombra um pouco maior, combinando com a base larga do personagem.
	var wide := PackedVector2Array()
	for pt in shadow.polygon:
		wide.append(Vector2(pt.x * 1.4, pt.y * 1.2))
	shadow.polygon = wide
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
		State.ATTACK:
			wanted = "punch"
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
	# +1000: mantem sempre positivo, acima do cenario (z 0), mesmo com Y negativo
	z_index = int(position.y) + 1000
	_update_sprite_animation()

func _start_attack() -> void:
	state = State.ATTACK
	attack_timer = attack_cooldown
	attack_active_timer = 0.3
	_play_sprite_once("punch")
	hitbox.activate(damage)
	var dir: float = sign(target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var base_x: float = abs(hitbox.position.x)
	hitbox.position.x = base_x * dir

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
	if uses_sprite and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	_try_drop_health_pack()
	died.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(visuals, "rotation", deg_to_rad(90.0), 0.4)
	tw.tween_callback(queue_free)

func _try_drop_health_pack() -> void:
	if health_pack_scene and randf() <= drop_chance and get_parent():
		var pack = health_pack_scene.instantiate()
		var drop_pos := global_position
		# adiciona depois da fase de fisica (evita erro "flushing queries")
		get_parent().add_child.call_deferred(pack)
		pack.set_deferred("global_position", drop_pos)
