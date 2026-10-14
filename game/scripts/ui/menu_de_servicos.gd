class_name MenuDeServicos
extends Control

## O menu de quem é comerciante e ferreiro ao mesmo tempo: depois da conversa, o jogador
## escolhe entre a loja e a bancada de aprimorar.
##
## Abre em EventBus.services_requested e pausa o jogo, como as telas a que ele leva. A
## loja e a bancada recusam abrir com o jogo pausado, então a escolha fecha este menu
## (e despausa) antes de pedir a tela seguinte.

@onready var titulo: Label = %Titulo
@onready var botao_loja: Button = %BotaoLoja
@onready var botao_aprimorar: Button = %BotaoAprimorar
@onready var botao_sair: Button = %BotaoSair

## O comerciante com quem o jogador falou. Null com o menu fechado.
var _perfil: PerfilNpc

func _ready() -> void:
	visible = false
	botao_loja.pressed.connect(_abrir_loja)
	botao_aprimorar.pressed.connect(_abrir_bancada)
	botao_sair.pressed.connect(fechar)
	EventBus.services_requested.connect(abrir)

## Este nó precisa vir depois do MenuPausa na cena, pelo mesmo motivo do calendário: no
## quadro em que o Esc fecha o menu, o MenuPausa já rodou, viu o jogo pausado e não abriu
## por cima.
func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed(&"ui_cancel"):
		fechar()

func abrir(perfil: PerfilNpc) -> void:
	if visible or get_tree().paused or perfil == null:
		return
	_perfil = perfil
	titulo.text = perfil.nome_exibido
	visible = true
	get_tree().paused = true
	botao_loja.grab_focus.call_deferred()

func fechar() -> void:
	if not visible:
		return
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false
	_perfil = null

## O perfil é guardado antes de fechar, porque fechar o esquece, e o sinal só sai depois,
## com o jogo já despausado.
func _abrir_loja() -> void:
	var perfil: PerfilNpc = _perfil
	fechar()
	EventBus.shop_requested.emit(perfil)

func _abrir_bancada() -> void:
	var perfil: PerfilNpc = _perfil
	fechar()
	EventBus.forge_requested.emit(perfil)
