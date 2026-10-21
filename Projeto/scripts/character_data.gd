extends Resource
class_name CharacterData

## SPRITES: cada personagem usa um SpriteFrames (spritesheet cortado no editor)
## nos campos "*_frames". Se o campo estiver vazio, o jogo usa a imagem
## estatica "texture" como plano B (1 frame). A altura (*_sprite_height) e a
## altura do FRAME: o jogo redimensiona mantendo a proporcao, com os pes na
## base do frame. Desenhe o personagem olhando para a DIREITA.

@export_category("Identidade")
@export var character_name: String = "Heroi"
@export var description: String = ""
@export var accent_color: Color = Color(1, 1, 1)

@export_category("Sprite do heroi")
@export var texture: Texture2D
@export var sprite_height: float = 52.0

@export_category("Atributos do jogador")
@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var melee_damage: float = 12.0
@export var projectile_damage: float = 8.0
@export var player_frames: SpriteFrames

@export_category("Inimigos associados")
@export var enemy_name: String = "Capanga"
@export var enemy_texture: Texture2D
@export var enemy_sprite_height: float = 46.0
@export var enemy_frames: SpriteFrames

@export_category("Chefao associado")
@export var boss_name: String = "Chefao"
@export var boss_texture: Texture2D
@export var boss_sprite_height: float = 78.0
@export var boss_max_health: float = 300.0
@export var boss_frames: SpriteFrames
