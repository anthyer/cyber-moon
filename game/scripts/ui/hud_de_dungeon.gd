class_name HudDeDungeon
extends Control

## Dentro da dungeon, mostra o nome dela e a linha do objetivo paralelo, no canto superior
## esquerdo, abaixo das barras de status. Fora da dungeon não aparece.
##
## Esta HUD não sabe qual é o objetivo: o objetivo paralelo avisa o próprio progresso, em
## texto pronto, pelo EventBus.dungeon_objective_changed.

const COR_DO_OBJETIVO: Color = Color(0.75, 0.8, 0.9)
const COR_DO_OBJETIVO_CONCLUIDO: Color = Color(0.3, 0.95, 1.0)

@onready var rotulo_do_nome: Label = %Nome
@onready var rotulo_do_objetivo: Label = %Objetivo

var _na_dungeon: bool = false

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como as
	# outras HUDs.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.dungeon_entered.connect(_ao_entrar)
	EventBus.dungeon_left.connect(_ao_sair)
	EventBus.dungeon_objective_changed.connect(_ao_mudar_objetivo)

func _process(_delta: float) -> void:
	visible = _na_dungeon and not get_tree().paused

func _ao_entrar() -> void:
	_na_dungeon = true
	var definicao: DefinicaoDeDungeon = DungeonManager.definicao_atual()
	rotulo_do_nome.text = definicao.nome if definicao != null else "Dungeon"
	# A linha do objetivo fica vazia até o objetivo desta dungeon avisar o primeiro texto.
	rotulo_do_objetivo.text = ""
	rotulo_do_objetivo.visible = false

func _ao_sair() -> void:
	_na_dungeon = false

func _ao_mudar_objetivo(texto: String, concluido: bool) -> void:
	rotulo_do_objetivo.text = texto
	rotulo_do_objetivo.visible = texto != ""
	rotulo_do_objetivo.add_theme_color_override(&"font_color", COR_DO_OBJETIVO_CONCLUIDO if concluido else COR_DO_OBJETIVO)
