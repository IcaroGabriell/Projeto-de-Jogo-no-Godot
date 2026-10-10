extends Area2D
class_name Hitbox

## Componente de area de ataque. Ative durante uma janela de tempo
## curta para causar dano a qualquer Hurtbox que esteja dentro dela.

@export var damage: float = 10.0
@export var knockback: float = 180.0
@export var active: bool = false

func _ready() -> void:
	monitoring = active
	monitorable = false
	area_entered.connect(_on_area_entered)

func activate(dmg: float = -1.0) -> void:
	if dmg >= 0.0:
		damage = dmg
	active = true
	monitoring = true

func deactivate() -> void:
	active = false
	monitoring = false

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	var hurtbox := area as Hurtbox
	if hurtbox:
		var dir := 1.0
		# Hitbox costuma estar em Personagem/Visuals/AttackPivot/Hitbox,
		# entao sobe 3 niveis para achar a raiz do personagem que ataca.
		var my_owner: Node2D = owner as Node2D
		var their_owner := hurtbox.get_parent() as Node2D
		if my_owner and their_owner:
			dir = sign(their_owner.global_position.x - my_owner.global_position.x)
			if dir == 0.0:
				dir = 1.0
		hurtbox.receive_hit(damage, dir * knockback)
