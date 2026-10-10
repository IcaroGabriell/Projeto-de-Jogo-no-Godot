extends Node
class_name Health

## Componente reutilizavel de vida. Anexe como filho de qualquer
## entidade (jogador, inimigo, chefao) que precise de vida/dano/morte.

signal health_changed(current: float, max_health: float)
signal damaged(amount: float)
signal died

@export var max_health: float = 100.0

var current_health: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	if current_health <= 0.0:
		current_health = max_health

func setup(new_max: float) -> void:
	max_health = new_max
	current_health = new_max
	is_dead = false
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = max(current_health - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func get_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
