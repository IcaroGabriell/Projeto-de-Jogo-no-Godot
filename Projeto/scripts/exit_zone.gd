extends Area2D
class_name ExitZone

## Zona de saida de uma fase. Fica desativada ate que a LevelManager
## a libere (quando todos os inimigos forem derrotados), simulando a
## abertura de passagem para a proxima cena.

signal player_entered

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = false
	monitorable = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_entered.emit()
