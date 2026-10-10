extends Resource
class_name CharacterData

## Recurso de dados de um personagem jogavel.
## Permite adicionar novos herois sem alterar codigo, apenas criando
## um novo arquivo .tres baseado neste script.
##
## SPRITES: arraste suas imagens (PNG) para os campos "texture" abaixo,
## ou simplesmente SUBSTITUA os arquivos em res://assets/sprites/.
## Qualquer tamanho funciona: o jogo redimensiona a imagem para a
## "sprite_height" indicada, mantendo a proporcao. Os pes ficam na
## base da imagem. Desenhe o personagem olhando para a DIREITA.

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

@export_category("Inimigos associados")
@export var enemy_name: String = "Capanga"
@export var enemy_texture: Texture2D
@export var enemy_sprite_height: float = 46.0

@export_category("Chefao associado")
@export var boss_name: String = "Chefao"
@export var boss_texture: Texture2D
@export var boss_sprite_height: float = 78.0
@export var boss_max_health: float = 300.0
