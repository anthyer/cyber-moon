extends Control

## O menu de entrada da demo: começar, ver os controles e sair.
##
## É a cena principal do projeto na branch da demo. O fundo animado (a cidade em
## parallax, os carros voadores e o título) é o CenarioDoMenu; este script só cuida dos
## botões. Começar troca de cena para a fase da demo, que abre com a tela de tutorial. Não há "continuar": a demo não tem save, e todo
## começo é um jogo novo.

const CENA_DA_DEMO: String = "res://scenes/levels/demo.tscn"

@onready var botao_jogar: Button = %BotaoJogar
@onready var botao_controles: Button = %BotaoControles
@onready var botao_sair: Button = %BotaoSair
@onready var painel_de_controles: Control = %PainelDeControles
@onready var botao_voltar: Button = %BotaoVoltar
@onready var botoes: Control = %Botoes

func _ready() -> void:
	botao_jogar.pressed.connect(_jogar)
	botao_controles.pressed.connect(_mostrar_controles.bind(true))
	botao_voltar.pressed.connect(_mostrar_controles.bind(false))
	botao_sair.pressed.connect(get_tree().quit)
	_mostrar_controles(false)

func _process(_delta: float) -> void:
	if painel_de_controles.visible and Input.is_action_just_pressed(&"ui_cancel"):
		_mostrar_controles(false)

func _jogar() -> void:
	get_tree().change_scene_to_file(CENA_DA_DEMO)

## Troca a coluna de botões pela tabela de controles, e volta. O foco vai junto, para o
## controle não ficar sem nada selecionado.
func _mostrar_controles(mostrar: bool) -> void:
	painel_de_controles.visible = mostrar
	botoes.visible = not mostrar
	if mostrar:
		botao_voltar.grab_focus()
	else:
		botao_jogar.grab_focus()
