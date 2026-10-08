class_name HudCreditos
extends Control

## O saldo de créditos do jogador, no canto da tela, logo abaixo do relógio.
##
## O crédito não ocupa slot do inventário: é um número do EconomyManager, e esta HUD é o
## único lugar em que o jogador o vê durante o jogo. Quando o saldo muda, o número pisca
## na cor do que aconteceu (verde ao ganhar, vermelho ao gastar), para a mudança não
## passar despercebida num canto da tela.

const COR_NORMAL: Color = Color(0.92, 0.95, 1.0)
const COR_AO_GANHAR: Color = Color(0.4, 1.0, 0.5)
const COR_AO_GASTAR: Color = Color(1.0, 0.4, 0.4)
const SEGUNDOS_DA_PISCADA: float = 0.5

@onready var rotulo_do_saldo: Label = %Saldo

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
	rotulo_do_saldo.add_theme_color_override(&"font_color", COR_NORMAL)

func _process(_delta: float) -> void:
	visible = not get_tree().paused

func _ao_mudar_saldo(saldo: int) -> void:
	var ganhou: bool = saldo > _saldo_mostrado
	var mudou: bool = saldo != _saldo_mostrado
	_saldo_mostrado = saldo
	rotulo_do_saldo.text = str(saldo)
	if not mudou:
		return
	if _piscada != null:
		_piscada.kill()
	rotulo_do_saldo.add_theme_color_override(&"font_color", COR_AO_GANHAR if ganhou else COR_AO_GASTAR)
	_piscada = create_tween()
	# A compra acontece com a loja aberta, e portanto com o jogo pausado. A piscada roda
	# mesmo assim, para a cor já ter voltado ao normal quando a HUD reaparecer.
	_piscada.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_piscada.tween_property(rotulo_do_saldo, "theme_override_colors/font_color", COR_NORMAL, SEGUNDOS_DA_PISCADA)
