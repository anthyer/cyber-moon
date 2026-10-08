class_name ContainerDeItens
extends RefCounted

## Um conjunto de slots de item fora do inventário do jogador: o conteúdo de um baú.
##
## Tem a mesma ideia do InventoryManager (slot vazio é null, pilha igual junta), mas é um
## objeto comum, e não um autoload, porque pode haver vários baús. As duas funções de
## transferência movem a pilha inteira entre este container e o inventário do jogador.

signal changed

var slots: Array[PilhaDeItens] = []

func _init(quantidade_de_slots: int = 24) -> void:
	slots.resize(quantidade_de_slots)

func total_de_slots() -> int:
	return slots.size()

func slot_em(indice: int) -> PilhaDeItens:
	if indice < 0 or indice >= slots.size():
		return null
	return slots[indice]

func esta_vazio() -> bool:
	for pilha in slots:
		if pilha != null and not pilha.esta_vazia():
			return false
	return true

## As pilhas que existem, sem os slots vazios.
func pilhas() -> Array[PilhaDeItens]:
	var lista: Array[PilhaDeItens] = []
	for pilha in slots:
		if pilha != null and not pilha.esta_vazia():
			lista.append(pilha)
	return lista

## Quantas unidades do item caberiam aqui, somando o espaço das pilhas iguais e os slots
## vazios. Serve para saber antes se uma pilha cabe inteira.
func espaco_para(item: Item) -> int:
	var limite: int = item.quantidade_maxima_por_pilha if item.empilhavel else 1
	var total: int = 0
	for pilha in slots:
		if pilha == null:
			total += limite
		elif pilha.item == item:
			total += pilha.espaco_livre()
	return total

## Guarda o item e devolve quanto não coube. Completa as pilhas iguais e depois ocupa os
## slots vazios, como o InventoryManager.
func adicionar(item: Item, quantidade: int) -> int:
	if item == null or quantidade <= 0:
		return 0
	var entrada: PilhaDeItens = PilhaDeItens.new(item, quantidade)
	var restante: int = quantidade
	for pilha in slots:
		if restante > 0 and pilha != null and pilha.item == item:
			restante = pilha.juntar(entrada)
	for indice in slots.size():
		if restante == 0:
			break
		if slots[indice] == null:
			var nova: PilhaDeItens = PilhaDeItens.new(item, 0)
			restante = nova.juntar(entrada)
			slots[indice] = nova
	if restante != quantidade:
		changed.emit()
	return restante

func esvaziar() -> void:
	slots.fill(null)
	changed.emit()

## Move a pilha inteira de um slot do inventário do jogador para cá. Devolve false, sem
## mexer em nada, se o slot está vazio, se quem chama recusa o item (a regra do baú, em
## aceita) ou se a pilha não cabe inteira.
func receber_do_inventario(indice_do_inventario: int, aceita: Callable) -> bool:
	var pilha: PilhaDeItens = InventoryManager.slot_em(indice_do_inventario)
	if pilha == null or pilha.esta_vazia():
		return false
	var item: Item = pilha.item
	var quantidade: int = pilha.quantidade
	if not aceita.call(item) or espaco_para(item) < quantidade:
		return false
	InventoryManager.remover_do_slot(indice_do_inventario, quantidade)
	adicionar(item, quantidade)
	return true

## Move a pilha inteira de um slot daqui de volta para o inventário. Devolve false, sem
## mexer em nada, se o slot está vazio ou se o inventário não tem espaço para ela toda.
func devolver_ao_inventario(indice_no_container: int) -> bool:
	var pilha: PilhaDeItens = slot_em(indice_no_container)
	if pilha == null or pilha.esta_vazia():
		return false
	var sobra: int = InventoryManager.adicionar_item(pilha.item, pilha.quantidade)
	if sobra == pilha.quantidade:
		return false
	if sobra > 0:
		# Coube só uma parte: o resto continua no baú.
		pilha.quantidade = sobra
	else:
		slots[indice_no_container] = null
	changed.emit()
	return sobra == 0
