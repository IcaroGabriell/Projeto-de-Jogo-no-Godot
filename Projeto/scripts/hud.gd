extends CanvasLayer
class_name HUD

## Interface durante a fase: nome/vida do jogador, nome da cena,
## contador de inimigos restantes, barra de vida do chefao (quando
## aplicavel) e mensagens rapidas (ex.: "caminho liberado").

@onready var health_bar: ProgressBar = %HealthBar
@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var enemy_label: Label = %EnemyLabel
@onready var message_label: Label = %MessageLabel
@onready var boss_bar_container: Control = %BossBarContainer
@onready var boss_bar: ProgressBar = %BossBar
@onready var boss_name_label: Label = %BossNameLabel

var message_tween: Tween

func setup(player: Player, level_name: String) -> void:
	level_label.text = level_name
	if player.character_data:
		name_label.text = player.character_data.character_name
		health_bar.max_value = player.character_data.max_health
		health_bar.value = player.character_data.max_health
	player.health_updated.connect(_on_player_health_updated)
	boss_bar_container.visible = false
	message_label.visible = false
	enemy_label.visible = true

func _on_player_health_updated(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func update_enemy_count(count: int) -> void:
	if count <= 0:
		enemy_label.text = "Inimigos restantes: 0"
	else:
		enemy_label.text = "Inimigos restantes: %d" % count

func setup_boss(boss: Boss) -> void:
	enemy_label.visible = false
	boss_bar_container.visible = true
	boss_name_label.text = boss.boss_name
	boss_bar.max_value = boss.max_health
	boss_bar.value = boss.max_health
	boss.health_updated.connect(func(c, m):
		boss_bar.max_value = m
		boss_bar.value = c
	)

func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(2.2)
	message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	message_tween.tween_callback(func(): message_label.visible = false)
