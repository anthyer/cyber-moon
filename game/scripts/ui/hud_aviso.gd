class_name HudAviso
extends Control

## Aviso curto no rodapé da tela, logo acima da barra rápida. Qualquer sistema pede um
## aviso emitindo EventBus.notice_requested, sem precisar saber que esta HUD existe (por
## exemplo, a GradeSolo recusando uma semente fora da estação).
##
## Um aviso novo substitui o anterior e reinicia o tempo, em vez de empilhar: avisos
## costumam vir de ações repetidas, e uma pilha de textos iguais só polui a tela.

const SEGUNDOS_NA_TELA: float = 2.5
const SEGUNDOS_DO_FADE: float = 0.4

@onready var painel: PanelContainer = %Painel
@onready var rotulo_do_texto: Label = %Texto

var _animacao: Tween

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como a
	# HUD de status e o relógio.
	process_mode = Node.PROCESS_MODE_ALWAYS
	painel.modulate.a = 0.0
	EventBus.notice_requested.connect(_ao_pedir_aviso)

func _process(_delta: float) -> void:
	visible = not get_tree().paused

func _ao_pedir_aviso(texto: String) -> void:
	rotulo_do_texto.text = texto
	if _animacao != null:
		_animacao.kill()
	painel.modulate.a = 1.0
	_animacao = create_tween()
	# O tempo do aviso para junto com o jogo. Sem isso, um aviso dado logo antes de
	# pausar acabaria escondido atrás do menu e o jogador nunca o leria.
	_animacao.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_animacao.tween_interval(SEGUNDOS_NA_TELA)
	_animacao.tween_property(painel, "modulate:a", 0.0, SEGUNDOS_DO_FADE)
