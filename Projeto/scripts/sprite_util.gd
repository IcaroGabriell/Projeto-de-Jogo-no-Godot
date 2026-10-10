extends RefCounted

## Utilitario para Sprite2D de personagens.
## Uso:  const SpriteUtil := preload("res://scripts/sprite_util.gd")
##       base_scale = SpriteUtil.fit(meu_sprite, textura, altura_desejada)
##
## Qualquer imagem (de qualquer tamanho) vira um personagem com a altura
## pedida, mantendo a proporcao. O ponto de ancoragem fica nos PES
## (centro da base da imagem = origem do personagem), entao a imagem
## sempre "pisa" no chao e a sombra continua no lugar certo.

static func fit(sprite: Sprite2D, tex: Texture2D, target_height: float) -> Vector2:
	if tex == null:
		tex = sprite.texture
	if tex == null:
		return Vector2.ONE
	sprite.texture = tex
	sprite.centered = false
	var size: Vector2 = tex.get_size()
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	var k: float = 1.0
	if target_height > 0.0 and size.y > 0.0:
		k = target_height / size.y
	sprite.scale = Vector2(k, k)
	return sprite.scale
