extends Node

## O item na mão do jogador é o que está no slot rápido selecionado, como no Minecraft.
##
## Este autoload guarda só qual dos 9 slots rápidos está selecionado. Quem tem os itens
## é o InventoryManager: trocar o item de lugar no menu troca o que está na mão sem este
## script saber. Slot vazio é uma seleção válida, e com ele (ou com a soqueira) o
## ataque é o soco.

signal slot_selecionado_alterado(indice: int)

## O que o jogador tem no começo, nessa ordem, para os slots 1 a 4 baterem com as
## teclas 1 a 4. A lista vira dado do plano 17, junto com as sementes iniciais.
const ITENS_INICIAIS: Array[String] = [
	"res://resources/items/armas/soqueira.tres",
	"res://resources/items/ferramentas/enxada.tres",
	"res://resources/items/ferramentas/regador.tres",
	"res://resources/items/ferramentas/picareta.tres",
]

var indice_selecionado: int = 0

func _ready() -> void:
	# Este autoload vem depois do InventoryManager na lista do project.godot, então o
	# inventário já existe aqui.
	for caminho in ITENS_INICIAIS:
		InventoryManager.adicionar_item(load(caminho) as Item, 1)

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

## A ferramenta na mão, ou null quando o item na mão não é ferramenta (soqueira,
## semente, slot vazio). O player usa isso para decidir entre usar ferramenta e socar.
func ferramenta_na_mao() -> Ferramenta:
	return item_na_mao() as Ferramenta
