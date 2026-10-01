extends Node

## O item na mão do jogador é o que está no slot rápido selecionado, como no Minecraft.
##
## Este autoload guarda só qual dos 9 slots rápidos está selecionado. Quem tem os itens
## é o InventoryManager: trocar o item de lugar no menu troca o que está na mão sem este
## script saber. Slot vazio é uma seleção válida, e com ele (ou com a soqueira) o
## ataque é o soco.

signal slot_selecionado_alterado(indice: int)

## O que o jogador tem no começo, com a quantidade, nessa ordem, para os slots 1 a 4
## baterem com as teclas 1 a 4. As sementes e os pães são estoque de teste até o plano 17, que
## define o inventário inicial de verdade e leva esta lista para um Resource.
const ITENS_INICIAIS: Array = [
	["res://resources/items/armas/soqueira.tres", 1],
	["res://resources/items/ferramentas/enxada.tres", 1],
	["res://resources/items/ferramentas/regador.tres", 1],
	["res://resources/items/ferramentas/picareta.tres", 1],
	["res://resources/items/sementes/semente_cenoura.tres", 5],
	["res://resources/items/sementes/semente_trigo.tres", 5],
	["res://resources/items/sementes/semente_beterraba.tres", 5],
	["res://resources/items/sementes/semente_repolho.tres", 5],
	["res://resources/items/sementes/semente_milho.tres", 5],
	["res://resources/items/sementes/semente_tomate.tres", 5],
	["res://resources/items/consumiveis/pao_de_trigo.tres", 3],
]

var indice_selecionado: int = 0

func _ready() -> void:
	# Este autoload vem depois do InventoryManager na lista do project.godot, então o
	# inventário já existe aqui.
	for caminho_e_quantidade in ITENS_INICIAIS:
		InventoryManager.adicionar_item(load(caminho_e_quantidade[0]) as Item, caminho_e_quantidade[1])

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
