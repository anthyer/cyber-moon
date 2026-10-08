class_name ResumoDeVendas
extends Control

## O aviso de quanto o baú de venda rendeu, mostrado de manhã, depois de o dia virar.
##
## A venda acontece na virada do dia, com a tela de transição do sono na frente. Mostrar
## na hora seria mostrar atrás dela. Por isso o resultado fica guardado, e o painel só
## aparece um pouco depois do day_started, quando a transição já saiu.
##
## Os dois tempos (a espera e o tempo na tela) são contados à mão no _process, só com o
## jogo rodando: assim abrir o inventário não gasta o aviso sem o jogador ter lido.

const SEGUNDOS_DE_ESPERA_APOS_O_DIA_COMECAR: float = 2.5
const SEGUNDOS_NA_TELA: float = 6.0
const SEGUNDOS_DO_FADE: float = 0.6

@onready var painel: PanelContainer = %Painel
@onready var rotulo_do_texto: Label = %Texto

## A venda que ainda não foi mostrada. Zero itens significa que não há nada guardado.
var _total_guardado: int = 0
var _itens_guardados: int = 0
## Negativo quando não há contagem em andamento.
var _segundos_ate_mostrar: float = -1.0
var _segundos_restantes_na_tela: float = 0.0

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como as
	# outras HUDs. As contagens abaixo é que param na pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	painel.modulate.a = 0.0
	EconomyManager.sale_completed.connect(_ao_vender)
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)

func _process(delta: float) -> void:
	visible = not get_tree().paused
	if get_tree().paused:
		return
	if _segundos_ate_mostrar >= 0.0:
		_segundos_ate_mostrar -= delta
		if _segundos_ate_mostrar < 0.0:
			_mostrar()
	if _segundos_restantes_na_tela > 0.0:
		_segundos_restantes_na_tela -= delta
		painel.modulate.a = clampf(_segundos_restantes_na_tela / SEGUNDOS_DO_FADE, 0.0, 1.0)

## Soma em vez de substituir: se por algum motivo duas vendas chegarem antes de o aviso
## aparecer, o jogador vê o total das duas.
func _ao_vender(total: int, itens: int) -> void:
	_total_guardado += total
	_itens_guardados += itens

func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	if _itens_guardados > 0:
		_segundos_ate_mostrar = SEGUNDOS_DE_ESPERA_APOS_O_DIA_COMECAR

func _mostrar() -> void:
	var palavra: String = "item" if _itens_guardados == 1 else "itens"
	rotulo_do_texto.text = "Vendas de ontem: %d %s, %d créditos." % [_itens_guardados, palavra, _total_guardado]
	_total_guardado = 0
	_itens_guardados = 0
	_segundos_restantes_na_tela = SEGUNDOS_NA_TELA
	painel.modulate.a = 1.0
