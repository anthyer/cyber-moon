extends Node

## O dinheiro do jogador: o saldo em créditos, comprar, vender e os marcos de progressão.
##
## O crédito é um número aqui, mostrado na HUD, e não um item no inventário. Comprar é
## cara a cara com o comerciante; vender é pelo baú de venda, recolhido na virada do dia.
##
## Os marcos da história dependem do total já vendido, e não do saldo, para gastar nunca
## atrasar a progressão.

signal credits_changed(saldo: int)
## O baú de venda foi recolhido. Não é emitido quando não havia nada nele.
signal sale_completed(total: int, itens: int)

const CAMINHO_DO_INVENTARIO_INICIAL: String = "res://resources/items/inventario_inicial.tres"
## Comprar custa o dobro do que o item vale na venda: produzir sempre rende mais que
## revender.
const MULTIPLICADOR_DE_COMPRA: float = 2.0
## A semente é a exceção: custa esta fração do valor da colheita que ela dá, para o
## plantio dar lucro desde o primeiro dia.
const FRACAO_DA_COLHEITA_NO_PRECO_DA_SEMENTE: float = 0.6
## Total vendido que desbloqueia cada marco do GameManager.
const MARCOS_POR_TOTAL_VENDIDO: Dictionary = {
	"marco_1": 2000,
	"marco_2": 10000,
	"marco_3": 30000,
}

var creditos: int = 0
var total_vendido: int = 0
## O motivo, em texto pronto para a tela, de a última compra ter sido recusada.
var ultimo_motivo_de_recusa: String = ""

func _ready() -> void:
	var inicial: InventarioInicial = load(CAMINHO_DO_INVENTARIO_INICIAL) as InventarioInicial
	creditos = inicial.creditos if inicial != null else 0

func pode_pagar(valor: int) -> bool:
	return creditos >= valor

func gastar(valor: int) -> bool:
	if valor < 0 or not pode_pagar(valor):
		return false
	creditos -= valor
	credits_changed.emit(creditos)
	return true

func receber(valor: int) -> void:
	if valor <= 0:
		return
	creditos += valor
	credits_changed.emit(creditos)

## Quanto custa comprar uma unidade. Vale o preço escrito no item (preco_de_compra),
## quando há; senão a regra da semente, para sementes; senão o dobro do valor de venda.
func preco_de_compra(item: Item) -> int:
	if item.preco_de_compra > 0:
		return item.preco_de_compra
	var semente: Semente = item as Semente
	if semente != null and semente.cultivo != null and semente.cultivo.item_colhido != null:
		return maxi(roundi(semente.cultivo.item_colhido.valor_de_venda * FRACAO_DA_COLHEITA_NO_PRECO_DA_SEMENTE), 1)
	return maxi(roundi(item.valor_de_venda * MULTIPLICADOR_DE_COMPRA), 1)

## Compra do comerciante: desconta os créditos e põe o item no inventário. Devolve false,
## sem mexer em nada, se falta crédito ou se a compra não cabe inteira no inventário.
func comprar(item: Item, quantidade: int) -> bool:
	if item == null or quantidade <= 0:
		return false
	var total: int = preco_de_compra(item) * quantidade
	if not pode_pagar(total):
		ultimo_motivo_de_recusa = "Créditos insuficientes."
		return false
	var sobra: int = InventoryManager.adicionar_item(item, quantidade)
	if sobra > 0:
		# Não coube tudo: desfaz o que entrou, para a compra ser tudo ou nada.
		InventoryManager.remover_item(item, quantidade - sobra)
		ultimo_motivo_de_recusa = "O inventário está cheio."
		return false
	gastar(total)
	ultimo_motivo_de_recusa = ""
	return true

## Quanto vale, em créditos, um conjunto de pilhas no baú de venda.
func valor_de(pilhas: Array[PilhaDeItens]) -> int:
	var total: int = 0
	for pilha in pilhas:
		total += pilha.item.valor_de_venda * pilha.quantidade
	return total

## Vende as pilhas: soma o valor, credita, conta para os marcos e avisa. Devolve o total.
## Quem chama é o baú de venda, na virada do dia, e é ele quem esvazia o próprio conteúdo.
func vender(pilhas: Array[PilhaDeItens]) -> int:
	if pilhas.is_empty():
		return 0
	var total: int = valor_de(pilhas)
	var unidades: int = 0
	for pilha in pilhas:
		unidades += pilha.quantidade
	total_vendido += total
	receber(total)
	sale_completed.emit(total, unidades)
	_conferir_marcos()
	return total

func _conferir_marcos() -> void:
	for marco: String in MARCOS_POR_TOTAL_VENDIDO:
		if total_vendido >= MARCOS_POR_TOTAL_VENDIDO[marco] and not GameManager.marco_esta_desbloqueado(marco):
			GameManager.desbloquear_marco(marco)
			EventBus.notice_requested.emit("Marco alcançado: as lojas têm novidades.")

# Save

func exportar_estado() -> Dictionary:
	return {"creditos": creditos, "total_vendido": total_vendido}

func importar_estado(dados: Dictionary) -> void:
	creditos = int(dados.get("creditos", creditos))
	total_vendido = int(dados.get("total_vendido", 0))
	credits_changed.emit(creditos)
