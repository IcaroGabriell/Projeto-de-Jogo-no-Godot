extends RefCounted

## Utilitario para sprites de personagens (Sprite2D ou AnimatedSprite2D).
##
## Uso no jogador / inimigo / chefao (AnimatedSprite2D):
##   const SpriteUtil := preload("res://scripts/sprite_util.gd")
##   base_scale = SpriteUtil.apply(sprite, frames, textura_reserva, altura)
##
## - `frames`: SpriteFrames do personagem (spritesheet cortado no editor).
## - `textura_reserva`: usada so se `frames` for null. Vira um SpriteFrames de
##   1 frame ("idle"), entao as imagens estaticas atuais continuam funcionando
##   enquanto os spritesheets ainda nao foram feitos.
##
## O ponto de ancoragem fica nos PES (centro da base do frame = origem do
## personagem), entao o sprite sempre "pisa" no chao e a sombra continua no
## lugar certo. A escala e calculada pelo frame da animacao "idle": use a
## mesma altura de frame em todas as animacoes de um personagem.

const FALLBACK_ANIM := &"idle"

## Aplica a aparencia a um AnimatedSprite2D e devolve a escala base.
static func apply(sprite: AnimatedSprite2D, frames: SpriteFrames, fallback_tex: Texture2D, target_height: float) -> Vector2:
	if frames == null and fallback_tex != null:
		frames = _frames_from_texture(fallback_tex)
	if frames != null:
		sprite.sprite_frames = frames
		if frames.has_animation(FALLBACK_ANIM):
			sprite.play(FALLBACK_ANIM)
	return fit(sprite, null, target_height)

## Ancora nos pes e escala para `target_height`. Aceita Sprite2D ou AnimatedSprite2D.
static func fit(sprite: Node2D, tex: Texture2D, target_height: float) -> Vector2:
	if sprite is AnimatedSprite2D:
		return _fit_animated(sprite as AnimatedSprite2D, target_height)
	return _fit_static(sprite as Sprite2D, tex, target_height)

static func _fit_static(sprite: Sprite2D, tex: Texture2D, target_height: float) -> Vector2:
	if tex == null:
		tex = sprite.texture
	if tex == null:
		return Vector2.ONE
	sprite.texture = tex
	sprite.centered = false
	var size: Vector2 = tex.get_size()
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	return _apply_scale(sprite, size, target_height)

static func _fit_animated(sprite: AnimatedSprite2D, target_height: float) -> Vector2:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames == null:
		return Vector2.ONE
	var anim: StringName = FALLBACK_ANIM
	if not frames.has_animation(anim) or frames.get_frame_count(anim) == 0:
		anim = sprite.animation
	if not frames.has_animation(anim) or frames.get_frame_count(anim) == 0:
		return Vector2.ONE
	var tex: Texture2D = frames.get_frame_texture(anim, 0)
	if tex == null:
		return Vector2.ONE
	sprite.centered = false
	var size: Vector2 = tex.get_size()
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
	return _apply_scale(sprite, size, target_height)

static func _apply_scale(sprite: Node2D, size: Vector2, target_height: float) -> Vector2:
	var k: float = 1.0
	if target_height > 0.0 and size.y > 0.0:
		k = target_height / size.y
	sprite.scale = Vector2(k, k)
	return sprite.scale

static func _frames_from_texture(tex: Texture2D) -> SpriteFrames:
	var f := SpriteFrames.new()
	if f.has_animation(&"default"):
		f.rename_animation(&"default", FALLBACK_ANIM)
	else:
		f.add_animation(FALLBACK_ANIM)
	f.set_animation_loop(FALLBACK_ANIM, true)
	f.add_frame(FALLBACK_ANIM, tex)
	return f
