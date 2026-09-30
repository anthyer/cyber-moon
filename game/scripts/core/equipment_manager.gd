extends Node

## O item em uso: uma das ferramentas ou a soqueira, que é a arma de bater do jogador.
##
## É a mesma coisa que o espaço EM_USO do inventário, e as duas pontas ficam
## sincronizadas: trocar pelas teclas atualiza o espaço, e equipar pelo menu atualiza o
## item em uso. Até o plano 05 trocar as teclas pela barra rápida, as duas formas de
## trocar convivem.

signal tool_equipped(ferramenta: Ferramenta)

# Este @export nao tem efeito em runtime: este autoload eh registrado como
# script puro (nao cena), entao nao existe Inspector pra editar esse array.
# Na pratica ele funciona como uma constante populada pelos preload() abaixo.
@export var ferramentas: Array[Ferramenta] = [
	preload("res://resources/items/ferramentas/enxada.tres"),
	preload("res://resources/items/ferramentas/regador.tres"),
	preload("res://resources/items/ferramentas/picareta.tres"),
]

## O que fica em uso quando nenhuma ferramenta está: o ataque de soco vem dela. O
## índice -1 de indice_atual quer dizer a soqueira.
@export var soqueira: Item = preload("res://resources/items/armas/soqueira.tres")

var indice_atual: int = -1

func _ready() -> void:
	# O jogador começa com a soqueira e as ferramentas no inventário, nessa ordem, para
	# os slots rápidos 1 a 4 baterem com as teclas 1 a 4. Este autoload vem depois do
	# InventoryManager na lista do project.godot, então o inventário já existe aqui.
	InventoryManager.adicionar_item(soqueira, 1)
	for ferramenta in ferramentas:
		InventoryManager.adicionar_item(ferramenta, 1)
	InventoryManager.equipment_changed.connect(_ao_mudar_equipamento)
	_sincronizar_espaco_em_uso()

func equipar_indice(indice: int) -> void:
	if indice < -1 or indice >= ferramentas.size():
		return
	indice_atual = indice
	tool_equipped.emit(ferramenta_atual())
	_sincronizar_espaco_em_uso()

func ciclar(direcao: int) -> void:
	var total: int = ferramentas.size() + 1
	var posicao: int = indice_atual + 1
	posicao = (posicao + direcao + total) % total
	equipar_indice(posicao - 1)

## A ferramenta em uso, ou null quando o item em uso é a soqueira.
func ferramenta_atual() -> Ferramenta:
	return ferramentas[indice_atual] if indice_atual >= 0 else null

## O item em uso, seja ferramenta ou soqueira. É o que a HUD mostra.
func item_em_uso() -> Item:
	var ferramenta: Ferramenta = ferramenta_atual()
	return ferramenta if ferramenta != null else soqueira

func _sincronizar_espaco_em_uso() -> void:
	var indice_do_slot: int = InventoryManager.indice_do_item(item_em_uso())
	if indice_do_slot == -1:
		InventoryManager.desequipar(InventoryManager.Espaco.EM_USO)
	else:
		InventoryManager.equipar(InventoryManager.Espaco.EM_USO, indice_do_slot)

## Só reage quando o item em uso mudou de fato, o que corta o vaivém entre os dois
## autoloads: o inventário avisa, esta função troca e não devolve o aviso. Espaço
## vazio ou soqueira no espaço voltam para o soco.
func _ao_mudar_equipamento(espaco: InventoryManager.Espaco, item: Item) -> void:
	if espaco != InventoryManager.Espaco.EM_USO:
		return
	var novo_indice: int = ferramentas.find(item as Ferramenta) if item is Ferramenta else -1
	if novo_indice == indice_atual:
		return
	indice_atual = novo_indice
	tool_equipped.emit(ferramenta_atual())
