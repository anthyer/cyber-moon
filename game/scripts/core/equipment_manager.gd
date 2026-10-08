extends Node

## O item na mão do jogador é o que está no slot rápido selecionado, como no Minecraft.
##
## Este autoload guarda só qual dos 9 slots rápidos está selecionado. Quem tem os itens
## é o InventoryManager: trocar o item de lugar no menu troca o que está na mão sem este
## script saber. Slot vazio é uma seleção válida, e com ele (ou com os cestos) o
## ataque é o soco.

signal slot_selecionado_alterado(indice: int)

## O que o jogador tem no começo (itens e créditos) fica num Resource, e não aqui. Os
## quatro primeiros itens são as ferramentas, para caírem nos slots das teclas 1 a 4.
const CAMINHO_DO_INVENTARIO_INICIAL: String = "res://resources/items/inventario_inicial.tres"

var indice_selecionado: int = 0

func _ready() -> void:
	# Este autoload vem depois do InventoryManager na lista do project.godot, então o
	# inventário já existe aqui.
	var inicial: InventarioInicial = load(CAMINHO_DO_INVENTARIO_INICIAL) as InventarioInicial
	if inicial == null:
		return
	for indice in inicial.itens.size():
		var quantidade: int = inicial.quantidades[indice] if indice < inicial.quantidades.size() else 1
		InventoryManager.adicionar_item(inicial.itens[indice], quantidade)

func selecionar(indice: int) -> void:
	if indice < 0 or indice >= InventoryManager.SLOTS_RAPIDOS:
		return
	if indice == indice_selecionado:
		return
	indice_selecionado = indice
	slot_selecionado_alterado.emit(indice_selecionado)

## Anda para o slot vizinho e dá a volta nas duas pontas, passando por slot vazio.
func ciclar(direcao: int) -> void:
	var total: int = InventoryManager.SLOTS_RAPIDOS
	selecionar((indice_selecionado + direcao + total) % total)

## O item no slot selecionado, ou null quando o slot está vazio.
func item_na_mao() -> Item:
	var pilha: PilhaDeItens = InventoryManager.slot_em(indice_selecionado)
	return pilha.item if pilha != null else null

## A ferramenta na mão, ou null quando o item na mão não é ferramenta (cestos,
## semente, slot vazio). O player usa isso para decidir entre usar ferramenta e socar.
func ferramenta_na_mao() -> Ferramenta:
	return item_na_mao() as Ferramenta
