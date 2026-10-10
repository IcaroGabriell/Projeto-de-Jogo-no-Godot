# Furia Urbana: Distrito 7

Protótipo completo e jogável de um beat'em up 2D com sensação de
profundidade (pseudo-3D), feito para **Godot Engine 4.7.1**.
Todo o visual é feito com **Sprite2D** (personagens, inimigos, chefões,
projétil, kit de vida, sombras e cenários). As imagens atuais são
*placeholders* gerados em `assets/sprites/` — troque-as pelas suas.

## Como abrir

1. Abra o Godot Engine **4.7.1**.
2. Clique em "Importar" e selecione a pasta `furia_urbana` (a que
   contém o arquivo `project.godot`).
3. Abra o projeto e pressione **F5** (ou o botão de Play) para rodar.
   A cena inicial (`main_menu.tscn`) já está configurada como
   "Main Scene" em `project.godot`.

## Controles

| Ação                       | Tecla            |
|-----------------------------|------------------|
| Mover para cima (profundidade) | W / Seta Cima  |
| Mover para baixo (profundidade)| S / Seta Baixo |
| Mover para esquerda          | A / Seta Esquerda |
| Mover para direita           | D / Seta Direita  |
| Pular                        | Espaço           |
| Ataque corpo a corpo          | J                |
| Lançar projétil               | K                |
| Pausar                       | Esc              |

Os controles podem ser remapeados em **Projeto > Configurações do
Projeto > Input Map**, onde as ações `move_up`, `move_down`,
`move_left`, `move_right`, `jump`, `attack_melee`, `attack_ranged`
e `pause` já estão configuradas.

## Estrutura do projeto

```
res://
├── project.godot
├── icon.svg
├── scripts/            # toda a lógica reutilizável (GDScript)
│   ├── character_data.gd   # Resource com os dados de cada herói
│   ├── health.gd            # componente de vida
│   ├── hitbox.gd / hurtbox.gd  # componentes de ataque/dano
│   ├── player.gd            # controlador do jogador (pseudo-3D)
│   ├── enemy.gd              # IA simples dos inimigos
│   ├── boss.gd                # IA dos chefões (2 tipos de ataque)
│   ├── projectile.gd          # projétil reutilizável
│   ├── health_pack.gd         # item de cura
│   ├── exit_zone.gd            # zona de saída/teletransporte
│   ├── level_manager.gd        # orquestra cada fase
│   ├── hud.gd / pause_menu.gd  # interface
│   ├── main_menu.gd / character_select.gd / game_over.gd / victory.gd
│   ├── game_manager.gd (autoload)       # estado global do jogo
│   └── transition_manager.gd (autoload) # fade entre cenas
├── assets/sprites/       # imagens (placeholders) — substitua pelas suas
├── characters/           # dados (.tres) dos 3 heróis jogáveis
├── scenes/
│   ├── main_menu.tscn
│   ├── character_select.tscn
│   ├── player.tscn / enemy.tscn / boss.tscn
│   ├── projectile.tscn / health_pack.tscn
│   ├── hud.tscn / pause_menu.tscn
│   ├── level_1.tscn / level_2.tscn / level_3.tscn (chefão)
│   ├── game_over.tscn / victory.tscn
```

## Como colocar suas imagens nos personagens

Cada herói tem um arquivo em `characters/hero_*.tres`. No Inspetor:

| Campo                | Para quê                         |
|----------------------|----------------------------------|
| `texture`            | imagem do herói                  |
| `enemy_texture`      | imagem dos inimigos dessa fase   |
| `boss_texture`       | imagem do chefão                 |
| `sprite_height`, `enemy_sprite_height`, `boss_sprite_height` | altura do personagem no jogo (px) |

Ou simplesmente **sobrescreva os PNGs** em `assets/sprites/` mantendo o nome.
Qualquer tamanho serve: o jogo redimensiona para a altura indicada
mantendo a proporção. Os pés ficam na base da imagem (centro-base) e o
personagem deve estar **olhando para a direita**. O cenário de cada fase
é uma imagem (`bg_level1..3.png`, nó `Background/Backdrop`), e o projétil,
o golpe (`slash.png`), o kit de vida e a sombra também são imagens.

## Como funciona o pseudo-3D

O personagem se move livremente no eixo X (esquerda/direita) e
também no eixo Y, que representa a **profundidade** dentro de um
corredor limitado (`depth_min` / `depth_max`, configurado por fase
na `LevelManager`). A ordenação visual — quem aparece na frente de
quem — é feita atualizando `z_index` de cada personagem a cada frame
com base na sua posição Y atual (quanto mais para baixo/perto da
câmera, maior o `z_index`, portanto desenhado na frente). O nó
`Background` de cada fase usa `z_index = -4000` para ficar sempre atrás
de qualquer personagem (inclusive quando o Y é negativo, ao subir no
corredor).

O pulo usa uma altura virtual (`jump_height`) simulada com
gravidade/velocidade vertical, deslocando apenas a parte visual do
personagem para cima, sem alterar a posição real de colisão — a
sombra no chão marca a posição real durante o pulo.

## Fluxo do jogo

`Menu → Seleção de Personagem → Cena 1 (3 inimigos) → Cena 2 (3
inimigos) → Cena 3 (Chefão) → Vitória`, com tela de derrota e opção
de reiniciar a qualquer momento em caso de morte.

## Adicionando um novo personagem

Crie um novo arquivo `.tres` em `characters/` baseado em
`scripts/character_data.gd` (pode duplicar um dos três existentes),
preencha os atributos, e adicione o caminho dele em
`GameManager.CHARACTER_PATHS` (`scripts/game_manager.gd`). O jogo
descobre automaticamente as novas opções na tela de seleção.
