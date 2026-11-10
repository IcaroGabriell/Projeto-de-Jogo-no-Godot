extends Node

## Autoload global. Guarda o personagem selecionado, a lista de
## personagens disponiveis e o nome da cena/fase atual (para a HUD).

var selected_character: CharacterData
var characters: Array[CharacterData] = []
var current_level_name: String = ""

# "Baralho" de capangas: sorteia sem repetir ate todos terem aparecido,
# garantindo variedade entre as fases do heroi (ex.: Kai).
var _henchman_bag: Array[int] = []

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
	reset_henchman_draw()

## Sorteia um capanga (Dictionary de CharacterData.enemy_sprite_sets) do heroi atual.
## Retorna {} se o heroi nao tem capangas com sprite.
func draw_henchman(data: CharacterData) -> Dictionary:
	if data == null or data.enemy_sprite_sets.is_empty():
		return {}
	if _henchman_bag.is_empty():
		for i in data.enemy_sprite_sets.size():
			_henchman_bag.append(i)
		_henchman_bag.shuffle()
	var idx: int = _henchman_bag.pop_back()
	if idx >= data.enemy_sprite_sets.size():
		return {}
	return data.enemy_sprite_sets[idx]

func reset_henchman_draw() -> void:
	_henchman_bag.clear()

func restart_game() -> void:
	reset_henchman_draw()
	TransitionManager.change_scene("res://scenes/level_1.tscn")

func go_to_main_menu() -> void:
	TransitionManager.change_scene("res://scenes/main_menu.tscn")
