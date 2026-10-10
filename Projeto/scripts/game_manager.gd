extends Node

## Autoload global. Guarda o personagem selecionado, a lista de
## personagens disponiveis e o nome da cena/fase atual (para a HUD).

var selected_character: CharacterData
var characters: Array[CharacterData] = []
var current_level_name: String = ""

const CHARACTER_PATHS := [
	"res://characters/hero_kai.tres",
	"res://characters/hero_maya.tres",
	"res://characters/hero_diesel.tres",
]

func _ready() -> void:
	characters.clear()
	for path in CHARACTER_PATHS:
		var data := load(path) as CharacterData
		if data:
			characters.append(data)
	if characters.size() > 0 and selected_character == null:
		selected_character = characters[0]

func select_character(index: int) -> void:
	if index >= 0 and index < characters.size():
		selected_character = characters[index]

func restart_game() -> void:
	TransitionManager.change_scene("res://scenes/level_1.tscn")

func go_to_main_menu() -> void:
	TransitionManager.change_scene("res://scenes/main_menu.tscn")
