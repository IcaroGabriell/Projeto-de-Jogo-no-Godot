extends Resource
class_name CharacterData

## Recurso de dados de um personagem jogavel.
## Permite adicionar novos herois sem alterar codigo, apenas criando
## um novo arquivo .tres baseado neste script.

@export_category("Identidade")
@export var character_name: String = "Heroi"
@export var description: String = ""
@export var body_color: Color = Color(0.85, 0.2, 0.2)
@export var head_color: Color = Color(0.9, 0.75, 0.55)
@export var accent_color: Color = Color(1, 1, 1)

@export_category("Sprites animados (opcional)")
## Se `sprite_animations` estiver vazio, o heroi continua sendo desenhado
## com os poligonos coloridos (body_color / head_color).
## Cada animacao e uma tira horizontal de quadros do mesmo tamanho:
## { "idle": {"path": "res://...png", "frames": 4, "fps": 6.0, "loop": true}, ... }
@export var portrait_path: String = ""
@export var sprite_frame_size: Vector2i = Vector2i(168, 168)
@export var sprite_scale: float = 0.45
@export var sprite_offset: Vector2 = Vector2(12, -69)
@export var sprite_animations: Dictionary = {}

@export_category("Sprites dos inimigos e do chefao (opcional)")
## Cada capanga e um Dictionary:
## { "name": "Jacare", "scale": 0.45, "offset": Vector2(0, -69), "animations": {...mesmo formato do heroi...} }
## Os capangas sao sorteados entre as fases (veja GameManager.draw_henchman).
## Se a lista estiver vazia, os inimigos continuam usando os poligonos coloridos.
@export var enemy_sprite_frame_size: Vector2i = Vector2i(168, 168)
@export var enemy_sprite_sets: Array = []
## Chefao: mesmo formato de um capanga (aceita tambem a animacao "throw", usada no ataque a distancia).
@export var boss_sprite_frame_size: Vector2i = Vector2i(168, 168)
@export var boss_sprite: Dictionary = {}

@export_category("Atributos do jogador")
@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var melee_damage: float = 12.0
@export var projectile_damage: float = 8.0

@export_category("Inimigos associados")
@export var enemy_name: String = "Capanga"
@export var enemy_body_color: Color = Color(0.25, 0.3, 0.55)
@export var enemy_head_color: Color = Color(0.5, 0.55, 0.75)

@export_category("Chefao associado")
@export var boss_name: String = "Chefao"
@export var boss_body_color: Color = Color(0.5, 0.1, 0.5)
@export var boss_head_color: Color = Color(0.75, 0.35, 0.75)
@export var boss_max_health: float = 300.0

func has_sprites() -> bool:
	return not sprite_animations.is_empty()

## Monta o SpriteFrames a partir das tiras de PNG. Retorna null se nenhuma
## animacao puder ser carregada (o jogo entao usa os poligonos).
func build_sprite_frames() -> SpriteFrames:
	return CharacterData.make_sprite_frames(sprite_animations, sprite_frame_size)

## Versao estatica (reutilizada por herois, capangas e chefoes).
static func make_sprite_frames(animations: Dictionary, frame_size: Vector2i) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var loaded := 0
	for anim_name in animations.keys():
		var info: Dictionary = animations[anim_name]
		var path: String = str(info.get("path", ""))
		if not ResourceLoader.exists(path):
			push_warning("Sprite nao encontrado: " + path)
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, float(info.get("fps", 8.0)))
		frames.set_animation_loop(anim_name, bool(info.get("loop", true)))
		var count: int = int(info.get("frames", 1))
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
			frames.add_frame(anim_name, atlas)
		loaded += 1
	if loaded == 0:
		return null
	return frames
