extends Control

@onready var cards := [%Card1, %Card2, %Card3]

func _ready() -> void:
	for i in cards.size():
		if i >= GameManager.characters.size():
			continue
		var data: CharacterData = GameManager.characters[i]
		var card: Control = cards[i]
		var portrait: ColorRect = card.get_node("VBox/Portrait")
		var portrait_head: ColorRect = portrait.get_node("PortraitHead")
		portrait.color = data.body_color
		portrait_head.color = data.head_color
		_apply_portrait_texture(data, portrait, portrait_head)
		card.get_node("VBox/NameLabel").text = data.character_name
		card.get_node("VBox/DescriptionLabel").text = data.description
		var select_button: Button = card.get_node("VBox/SelectButton")
		select_button.pressed.connect(_on_select.bind(i))

func _on_select(index: int) -> void:
	GameManager.select_character(index)
	TransitionManager.change_scene("res://scenes/level_1.tscn")

## Se o heroi tem um retrato em PNG (ex.: Kai), mostra a imagem no lugar do bloco colorido.
func _apply_portrait_texture(data: CharacterData, portrait: ColorRect, portrait_head: ColorRect) -> void:
	if data.portrait_path == "" or not ResourceLoader.exists(data.portrait_path):
		return
	var tex := load(data.portrait_path) as Texture2D
	if tex == null:
		return
	portrait.color = Color(0.13, 0.15, 0.24, 1)
	portrait_head.visible = false
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
