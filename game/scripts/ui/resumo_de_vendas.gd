class_name ResumoDeVendas
extends Control

## O aviso de quanto o baú de venda rendeu, mostrado de manhã, depois de o dia virar.
##
## O visual é o do mock: o cupom fiscal de papel do caminhão do Rafa ("Entregas Duarte"),
## meio torto, com a hora e o dia em que ele recolheu, item por item, as unidades e o
## total. O papel é a única peça clara da interface; a tinta é a cor `noite` do Theme.
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
## O tracejado do cupom é mais claro que a tinta do texto.
const OPACIDADE_DO_TRACEJADO: float = 0.45
## A borda de baixo do cupom, rasgada em dentes, como o recorte do mock.
const LARGURA_DO_DENTE: float = 18.0
const ALTURA_DO_DENTE: float = 8.0

@onready var painel: PanelContainer = %Painel
@onready var linhas: VBoxContainer = %Linhas
@onready var rotulo_de_quando: Label = %Quando
@onready var lista_de_itens: VBoxContainer = %Itens
@onready var rotulo_de_unidades: Label = %Quantidade
@onready var rotulo_do_total: Label = %ValorTotal

## A venda que ainda não foi mostrada. Zero itens significa que não há nada guardado.
var _total_guardado: int = 0
var _itens_guardados: int = 0
## Os itens vendidos, na ordem em que saíram do baú, sem repetir.
var _itens_vendidos: Array[Item] = []
var _hora_da_venda: float = 0.0
var _dia_da_venda: int = 0
## Negativo quando não há contagem em andamento.
var _segundos_ate_mostrar: float = -1.0
var _segundos_restantes_na_tela: float = 0.0

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como as
	# outras HUDs. As contagens abaixo é que param na pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	painel.modulate.a = 0.0
	painel.resized.connect(_ao_mudar_tamanho_do_cupom)
	painel.draw.connect(_desenhar_dentes)
	_pintar_com_tinta(linhas)
	EconomyManager.item_sold.connect(_ao_vender_item)
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

func _ao_vender_item(item: Item) -> void:
	if not _itens_vendidos.has(item):
		_itens_vendidos.append(item)

## Soma em vez de substituir: se por algum motivo duas vendas chegarem antes de o aviso
## aparecer, o jogador vê o total das duas.
func _ao_vender(total: int, itens: int) -> void:
	_total_guardado += total
	_itens_guardados += itens
	_hora_da_venda = DayCycleManager.hora_atual
	_dia_da_venda = DayCycleManager.numero_do_dia

func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	if _itens_guardados > 0:
		_segundos_ate_mostrar = SEGUNDOS_DE_ESPERA_APOS_O_DIA_COMECAR

func _mostrar() -> void:
	rotulo_de_quando.text = "recolhido às %s, dia %d" % [_texto_da_hora(_hora_da_venda), _dia_da_venda]
	_montar_itens()
	rotulo_de_unidades.text = str(_itens_guardados)
	rotulo_do_total.text = str(_total_guardado)
	_total_guardado = 0
	_itens_guardados = 0
	_itens_vendidos.clear()
	_segundos_restantes_na_tela = SEGUNDOS_NA_TELA
	painel.modulate.a = 1.0

## Uma linha por item vendido, com o preço de uma unidade. O sinal da venda não diz
## quantas unidades de cada item saíram, só o total, então o cupom não inventa a conta
## por item.
func _montar_itens() -> void:
	for filho in lista_de_itens.get_children():
		lista_de_itens.remove_child(filho)
		filho.queue_free()
	for item in _itens_vendidos:
		var linha: HBoxContainer = HBoxContainer.new()
		var nome: Label = Label.new()
		nome.text = item.nome
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(nome)
		var preco: Label = Label.new()
		preco.text = "%d cada" % item.valor_de_venda
		linha.add_child(preco)
		lista_de_itens.add_child(linha)
	_pintar_com_tinta(lista_de_itens)

## Todo texto do cupom vai na cor da tinta, e o tracejado um pouco mais claro.
func _pintar_com_tinta(no: Node) -> void:
	for filho in no.get_children():
		if filho is Label:
			(filho as Label).add_theme_color_override(&"font_color", CoresDaInterface.noite())
			if (filho as Label).text.begins_with("- -"):
				(filho as Label).modulate.a = OPACIDADE_DO_TRACEJADO
		_pintar_com_tinta(filho)

## O cupom gira em volta do próprio centro, e não do canto.
func _ao_mudar_tamanho_do_cupom() -> void:
	painel.pivot_offset = painel.size / 2.0

## Os dentes do rasgo, desenhados logo abaixo do papel, na mesma cor dele.
func _desenhar_dentes() -> void:
	var papel: StyleBoxFlat = painel.get_theme_stylebox(&"panel") as StyleBoxFlat
	if papel == null:
		return
	var y: float = painel.size.y
	var x: float = 0.0
	while x < painel.size.x:
		var largura: float = minf(LARGURA_DO_DENTE, painel.size.x - x)
		var dente: PackedVector2Array = [Vector2(x, y), Vector2(x + largura, y), Vector2(x + largura / 2.0, y + ALTURA_DO_DENTE)]
		painel.draw_colored_polygon(dente, papel.bg_color)
		x += LARGURA_DO_DENTE

func _texto_da_hora(hora: float) -> String:
	var hora_do_relogio: int = int(hora) % 24
	var minutos: int = int((hora - floorf(hora)) * 60.0)
	return "%02d:%02d" % [hora_do_relogio, minutos]
