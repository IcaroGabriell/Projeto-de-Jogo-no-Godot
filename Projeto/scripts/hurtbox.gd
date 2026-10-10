extends Area2D
class_name Hurtbox

## Componente de area vulneravel. Recebe dano de qualquer Hitbox
## que a atinja e repassa para o componente Health configurado.

signal hit_received(amount: float, knockback_x: float)

@export var health_path: NodePath

var health_node: Health

func _ready() -> void:
	monitoring = false
	monitorable = true
	if health_path != NodePath():
		health_node = get_node_or_null(health_path) as Health

func receive_hit(amount: float, knockback_x: float) -> void:
	if health_node:
		health_node.take_damage(amount)
	hit_received.emit(amount, knockback_x)
