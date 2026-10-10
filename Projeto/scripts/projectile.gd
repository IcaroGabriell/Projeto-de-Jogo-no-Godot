extends Area2D
class_name Projectile

## Projetil reutilizavel para jogador e chefoes. A camada-alvo
## (collision_mask) e definida em runtime pelo metodo setup(), o que
## permite que o mesmo componente sirva tanto para atacar inimigos
## quanto para atacar o jogador.

@export var speed: float = 420.0
@export var lifetime: float = 2.0
@export var damage: float = 8.0

var direction: float = 1.0
var life_timer: float = 0.0
var impacted: bool = false

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	life_timer = lifetime

func setup(dir: float, dmg: float, target_layer_bit: int) -> void:
	direction = sign(dir) if dir != 0.0 else 1.0
	damage = dmg
	collision_mask = target_layer_bit
	scale.x = direction

func _process(delta: float) -> void:
	if impacted:
		return
	position.x += direction * speed * delta
	life_timer -= delta
	if life_timer <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impacted:
		return
	var hurtbox := area as Hurtbox
	if hurtbox:
		hurtbox.receive_hit(damage, direction * 120.0)
		_impact()

func _impact() -> void:
	impacted = true
	# Usa set_deferred para desativar a monitorizacao em seguranca
	# sem causar erro no Physics Server durante a colisao
	set_deferred("monitoring", false)
	
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.8 * direction, 1.8), 0.12)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)
