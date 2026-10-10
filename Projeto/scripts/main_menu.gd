extends Control

func _ready() -> void:
	get_tree().paused = false
	%PlayButton.pressed.connect(_on_play_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%PlayButton.grab_focus()

func _on_play_pressed() -> void:
	TransitionManager.change_scene("res://scenes/character_select.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
