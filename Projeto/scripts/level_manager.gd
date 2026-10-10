extends Node2D
class_name LevelManager

## Controlador central de uma fase. Responsavel por:
## - instanciar o jogador com o personagem escolhido
## - configurar inimigos/chefao com a aparencia do personagem
## - contar inimigos restantes e liberar a saida quando zerar
## - disparar a transicao para a proxima cena / vitoria / derrota
## Mantem toda a mudanca de estado central, evitando que varios
## sistemas controlem a troca de fase ao mesmo tempo.

@export var level_display_name: String = "Cena 1"
@export var is_boss_level: bool = false
@export var next_level_path: String = ""

@export_category("Limites do corredor (profundidade / eixo Y)")
@export var depth_min: float = -70.0
@export var depth_max: float = 70.0

@export_category("Limites da camera (mundo)")
@export var camera_limit_left: int = -200
@export var camera_limit_right: int = 2000
@export var camera_limit_top: int = -300
@export var camera_limit_bottom: int = 400

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var entities: Node2D = $Entities
@onready var enemies_container: Node2D = $Entities/Enemies
@onready var exit_zone: ExitZone = $ExitZone
@onready var hud: HUD = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const HEALTH_PACK_SCENE := preload("res://scenes/health_pack.tscn")

var player: Player
var boss: Boss
var enemies_remaining: int = 0

func _ready() -> void:
	GameManager.current_level_name = level_display_name
	_spawn_player()
	if is_boss_level:
		_setup_boss()
	else:
		_setup_enemies()
	exit_zone.player_entered.connect(_on_exit_reached)
	if pause_menu:
		pause_menu.setup()

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.character_data = GameManager.selected_character
	player.depth_min = depth_min
	player.depth_max = depth_max
	entities.add_child(player)
	player.global_position = player_spawn.global_position
	player.died.connect(_on_player_died)

	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.limit_left = camera_limit_left
		cam.limit_right = camera_limit_right
		cam.limit_top = camera_limit_top
		cam.limit_bottom = camera_limit_bottom
		cam.make_current()

	hud.setup(player, level_display_name)

func _setup_enemies() -> void:
	var data: CharacterData = GameManager.selected_character
	var enemy_list := enemies_container.get_children()
	enemies_remaining = enemy_list.size()
	for child in enemy_list:
		var enemy := child as Enemy
		if enemy:
			enemy.depth_min = depth_min
			enemy.depth_max = depth_max
			if data:
				enemy.configure(data.enemy_name, data.enemy_texture, data.enemy_sprite_height)
			enemy.health_pack_scene = HEALTH_PACK_SCENE
			enemy.died.connect(_on_enemy_died)
	hud.update_enemy_count(enemies_remaining)
	if enemies_remaining <= 0:
		_open_exit()

func _setup_boss() -> void:
	var data: CharacterData = GameManager.selected_character
	boss = entities.get_node_or_null("Boss") as Boss
	if not boss:
		return
	boss.depth_min = depth_min
	boss.depth_max = depth_max
	if data:
		boss.configure(data.boss_name, data.boss_texture, data.boss_sprite_height, data.boss_max_health)
	boss.died.connect(_on_boss_died)
	hud.setup_boss(boss)

func _on_enemy_died(_enemy: Node = null) -> void:
	enemies_remaining = max(enemies_remaining - 1, 0)
	hud.update_enemy_count(enemies_remaining)
	if enemies_remaining <= 0:
		_open_exit()

func _open_exit() -> void:
	# Alterado para set_deferred para evitar erro ao liberar a saída durante a morte do último inimigo
	exit_zone.set_deferred("monitoring", true)
	exit_zone.set_deferred("monitorable", true)
	hud.show_message("Caminho liberado! Siga em frente.")

func _on_exit_reached() -> void:
	if next_level_path == "":
		return
	# Alterado para set_deferred ao desativar no momento em que o jogador entra na área
	exit_zone.set_deferred("monitoring", false)
	TransitionManager.change_scene(next_level_path)

func _on_boss_died() -> void:
	hud.show_message("Chefao derrotado!")
	await get_tree().create_timer(1.6).timeout
	TransitionManager.change_scene("res://scenes/victory.tscn")

func _on_player_died() -> void:
	hud.show_message("Voce foi derrotado...")
	await get_tree().create_timer(1.2).timeout
	TransitionManager.change_scene("res://scenes/game_over.tscn")
