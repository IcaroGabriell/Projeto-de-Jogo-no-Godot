extends Area2D
class_name HealthPack

## Item de recuperacao de vida. Fica flutuando levemente no chao e
## cura o jogador ao ser tocado, sem nunca ultrapassar a vida maxima
## (a logica de limite fica dentro do componente Health).

@export var heal_amount: float = 20.0

@onready var visual: Sprite2D = $Visual

var bob_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false

func _process(delta: float) -> void:
	bob_time += delta
	visual.position.y = -10.0 + sin(bob_time * 4.0) * 4.0
	z_index = int(position.y)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var health_node := body.get_node_or_null("Health") as Health
	if health_node:
		health_node.heal(heal_amount)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
