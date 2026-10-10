extends Control

func _ready() -> void:
	get_tree().paused = false
	%RestartButton.pressed.connect(_on_restart_pressed)
	%MenuButton.pressed.connect(_on_menu_pressed)
	%RestartButton.grab_focus()

func _on_restart_pressed() -> void:
	GameManager.restart_game()

func _on_menu_pressed() -> void:
	GameManager.go_to_main_menu()
