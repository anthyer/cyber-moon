class_name HudAviso
extends Control

## Aviso curto no alto da tela, no meio. Qualquer sistema pede um
## aviso emitindo EventBus.notice_requested, sem precisar saber que esta HUD existe (por
## exemplo, a GradeSolo recusando uma semente fora da estação).
##
## Um aviso novo substitui o anterior e reinicia o tempo, em vez de empilhar: avisos
## costumam vir de ações repetidas, e uma pilha de textos iguais só polui a tela.
##
## Durante a luta com chefe a barra dele ocupa o mesmo lugar no alto. O aviso então desce
## para logo abaixo dela e volta ao alto quando ela some. A barra é achada pelo grupo
## "barra_do_chefe", sem esta HUD conhecer a do chefe.
##
## O visual é o do aviso dos mocks: o painel neutro do Theme, compacto, com uma faixa
## verde na esquerda.

const SEGUNDOS_NA_TELA: float = 2.5
const SEGUNDOS_DO_FADE: float = 0.4
## As margens de dentro do aviso, menores que as do painel do Theme, para ele caber no
## alto da tela entre a HUD de status e o relógio.
const MARGEM_NOS_LADOS: float = 10.0
const MARGEM_EM_CIMA_E_EMBAIXO: float = 6.0
## Aviso mais largo que isto quebra em mais de uma linha, para não cobrir a HUD de status
## nem o relógio.
const LARGURA_MAXIMA_DO_TEXTO: float = 460.0
## O grupo da barra do chefe e o espaço entre ela e o aviso, quando ela está na tela.
const GRUPO_DA_BARRA_DO_CHEFE: StringName = &"barra_do_chefe"
const ESPACO_ABAIXO_DA_BARRA_DO_CHEFE: float = 8.0

@onready var painel: PanelContainer = %Painel
@onready var rotulo_do_texto: Label = %Texto
@onready var faixa: ColorRect = %Faixa

var _animacao: Tween
## A distância do topo da tela que vem da cena, para voltar a ela quando a barra some.
var _topo_normal: float
var _altura: float

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como a
	# HUD de status e o relógio.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_topo_normal = offset_top
	_altura = offset_bottom - offset_top
	painel.modulate.a = 0.0
	faixa.color = CoresDaInterface.verde()
	_deixar_o_painel_compacto()
	EventBus.notice_requested.connect(_ao_pedir_aviso)

func _process(_delta: float) -> void:
	visible = not get_tree().paused
	_fugir_da_barra_do_chefe()

func _fugir_da_barra_do_chefe() -> void:
	var topo: float = _topo_normal
	var barra: Control = get_tree().get_first_node_in_group(GRUPO_DA_BARRA_DO_CHEFE) as Control
	if barra != null and barra.is_visible_in_tree():
		topo = barra.get_global_rect().end.y + ESPACO_ABAIXO_DA_BARRA_DO_CHEFE
	offset_top = topo
	offset_bottom = topo + _altura

func _ao_pedir_aviso(texto: String) -> void:
	_escrever(texto)
	if _animacao != null:
		_animacao.kill()
	painel.modulate.a = 1.0
	_animacao = create_tween()
	# O tempo do aviso para junto com o jogo. Sem isso, um aviso dado logo antes de
	# pausar acabaria escondido atrás do menu e o jogador nunca o leria.
	_animacao.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_animacao.tween_interval(SEGUNDOS_NA_TELA)
	_animacao.tween_property(painel, "modulate:a", 0.0, SEGUNDOS_DO_FADE)

## Usa o painel neutro do Theme com margens menores. A cópia é só deste aviso.
func _deixar_o_painel_compacto() -> void:
	var caixa: StyleBox = painel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	caixa.content_margin_left = MARGEM_NOS_LADOS
	caixa.content_margin_right = MARGEM_NOS_LADOS
	caixa.content_margin_top = MARGEM_EM_CIMA_E_EMBAIXO
	caixa.content_margin_bottom = MARGEM_EM_CIMA_E_EMBAIXO
	painel.add_theme_stylebox_override(&"panel", caixa)

func _escrever(texto: String) -> void:
	rotulo_do_texto.autowrap_mode = TextServer.AUTOWRAP_OFF
	rotulo_do_texto.custom_minimum_size.x = 0.0
	rotulo_do_texto.text = texto
	if rotulo_do_texto.get_minimum_size().x > LARGURA_MAXIMA_DO_TEXTO:
		rotulo_do_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rotulo_do_texto.custom_minimum_size.x = LARGURA_MAXIMA_DO_TEXTO
