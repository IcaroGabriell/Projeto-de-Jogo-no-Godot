extends CanvasLayer

## Autoload global. Controla a transicao (fade para preto) entre cenas,
## dando a sensacao de "teletransporte" ao mudar de fase.

var fade_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_rect)

func change_scene(path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.35)
	await tw.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(fade_rect, "color:a", 0.0, 0.35)
	await tw2.finished
	is_transitioning = false
