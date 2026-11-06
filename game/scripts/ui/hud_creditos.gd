class_name HudCreditos
extends Control

## O saldo de créditos do jogador, no canto da tela, logo abaixo do relógio.
##
## O crédito não ocupa slot do inventário: é um número do EconomyManager, e esta HUD é o
## único lugar em que o jogador o vê durante o jogo. Quando o saldo muda, aparece ao lado
## a diferença ("+45" em verde ao ganhar, "-30" em âmbar ao gastar) e o número pisca na
## mesma cor, para a mudança não passar despercebida num canto da tela. Âmbar, e não
## vermelho: o jogo não usa vermelho.

const SEGUNDOS_DA_PISCADA: float = 0.5
## Quanto tempo a diferença fica ao lado do saldo antes de sumir.
const SEGUNDOS_DA_DIFERENCA: float = 2.5

@onready var painel: PanelContainer = $Painel
@onready var rotulo_do_saldo: Label = %Saldo
@onready var rotulo_da_variacao: Label = %Variacao

## O último saldo mostrado, para saber se a mudança foi ganho ou gasto.
var _saldo_mostrado: int = 0
var _piscada: Tween

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como o
	# relógio e a HUD de status.
	process_mode = Node.PROCESS_MODE_ALWAYS
	EconomyManager.credits_changed.connect(_ao_mudar_saldo)
	_saldo_mostrado = EconomyManager.creditos
	rotulo_do_saldo.text = str(_saldo_mostrado)
	rotulo_do_saldo.add_theme_color_override(&"font_color", CoresDaInterface.texto())
	_mostrar_variacao(false)

func _process(_delta: float) -> void:
	visible = not get_tree().paused

func _ao_mudar_saldo(saldo: int) -> void:
	var diferenca: int = saldo - _saldo_mostrado
	_saldo_mostrado = saldo
	rotulo_do_saldo.text = str(saldo)
	if diferenca == 0:
		return
	if _piscada != null:
		_piscada.kill()
	var cor: Color = CoresDaInterface.verde() if diferenca > 0 else CoresDaInterface.ambar()
	rotulo_do_saldo.add_theme_color_override(&"font_color", cor)
	rotulo_da_variacao.text = "%+d" % diferenca
	rotulo_da_variacao.add_theme_color_override(&"font_color", cor)
	_mostrar_variacao(true)
	_piscada = create_tween()
	# A compra acontece com a loja aberta, e portanto com o jogo pausado. A piscada roda
	# mesmo assim, para a cor já ter voltado ao normal quando a HUD reaparecer.
	_piscada.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_piscada.tween_property(rotulo_do_saldo, "theme_override_colors/font_color", CoresDaInterface.texto(), SEGUNDOS_DA_PISCADA)
	_piscada.parallel().tween_interval(SEGUNDOS_DA_DIFERENCA)
	_piscada.tween_callback(_mostrar_variacao.bind(false))

## O painel fica preso pela direita; ao esconder a diferença ele encolhe para a esquerda
## voltar ao tamanho do saldo.
func _mostrar_variacao(mostrar: bool) -> void:
	rotulo_da_variacao.visible = mostrar
	painel.reset_size()
