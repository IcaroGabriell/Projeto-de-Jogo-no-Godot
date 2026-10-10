extends Control

@onready var cards := [%Card1, %Card2, %Card3]

func _ready() -> void:
	for i in cards.size():
		if i >= GameManager.characters.size():
			continue
		var data: CharacterData = GameManager.characters[i]
		var card: Control = cards[i]
		card.get_node("VBox/Portrait").texture = data.texture
		card.get_node("VBox/NameLabel").text = data.character_name
		card.get_node("VBox/DescriptionLabel").text = data.description
		var select_button: Button = card.get_node("VBox/SelectButton")
		select_button.pressed.connect(_on_select.bind(i))

func _on_select(index: int) -> void:
	GameManager.select_character(index)
	TransitionManager.change_scene("res://scenes/level_1.tscn")
