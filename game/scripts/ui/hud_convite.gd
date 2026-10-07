class_name HudConvite
extends Control

## O aviso de convite para a dungeon: quem chamou, e os botões de aceitar e recusar.
##
## Não pausa o jogo, porque o convite pode chegar a qualquer hora e o jogador decide se
## para o que está fazendo. Sem resposta em SEGUNDOS_PARA_RESPONDER, o convite conta como
## recusado, para quem convidou não ficar esperando para sempre.

const SEGUNDOS_PARA_RESPONDER: float = 20.0

@onready var painel: PanelContainer = %Painel
@onready var rotulo_do_texto: Label = %Texto
@onready var botao_aceitar: Button = %BotaoAceitar
@onready var botao_recusar: Button = %BotaoRecusar

## Há um convite esperando resposta. Fica separado do visible porque o painel se esconde
## com o jogo pausado sem que o convite seja perdido.
var _ha_convite: bool = false
var _segundos_restantes: float = 0.0

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir e de
	# voltar, como as outras HUDs.
	process_mode = Node.PROCESS_MODE_ALWAYS
	painel.visible = false
	botao_aceitar.pressed.connect(_responder.bind(true))
	botao_recusar.pressed.connect(_responder.bind(false))
	LobbyManager.invite_received.connect(_ao_receber_convite)
	# Se a sala do convite acabou antes da resposta, não há mais o que responder.
	LobbyManager.room_closed.connect(_esquecer_o_convite)
	# O convite também pode ser respondido por outro caminho; entrando na equipe ou na
	# dungeon, o painel não tem mais o que perguntar.
	LobbyManager.dungeon_started.connect(_esquecer_o_convite)

func _process(delta: float) -> void:
	painel.visible = _ha_convite and not get_tree().paused
	if not _ha_convite:
		return
	# O tempo do convite para junto com o jogo. Sem isso, um convite que chegasse com o
	# inventário aberto poderia expirar sem o jogador ter visto.
	if get_tree().paused:
		return
	_segundos_restantes -= delta
	if _segundos_restantes <= 0.0:
		_responder(false)

func _ao_receber_convite(_de: String, nome: String) -> void:
	rotulo_do_texto.text = "%s chamou você para a dungeon." % nome
	_ha_convite = true
	_segundos_restantes = SEGUNDOS_PARA_RESPONDER

func _responder(aceita: bool) -> void:
	if not _ha_convite:
		return
	_esquecer_o_convite()
	LobbyManager.responder_convite(aceita)

func _esquecer_o_convite() -> void:
	_ha_convite = false
	painel.visible = false
