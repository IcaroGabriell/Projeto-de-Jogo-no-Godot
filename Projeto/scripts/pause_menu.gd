extends CanvasLayer
class_name PauseMenu

## Menu de pausa simples, acionado pela acao "pause" (Esc).
## Usa PROCESS_MODE_ALWAYS para continuar recebendo input mesmo com
## o jogo pausado (get_tree().paused = true).

@onready var panel: Control = %PausePanel

func setup() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	var resume_btn: Button = %ResumeButton
	var menu_btn: Button = %MenuButton
	resume_btn.pressed.connect(_on_resume_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	panel.visible = get_tree().paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	panel.visible = false

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to_main_menu()
