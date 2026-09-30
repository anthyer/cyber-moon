extends Node

## Inventário do jogador em slots, estilo Rune Factory e Minecraft.
##
## São 36 slots num array só: os índices de 0 a 8 são a barra rápida e de 9 a 35 a
## matriz principal de 3 linhas por 9 colunas, como no Minecraft. A matriz tem a mesma
## largura da barra rápida, então cada coluna da matriz fica em cima de um slot rápido.
## A barra rápida conta na capacidade total. Slot vazio é null.
##
## Equipar não copia o item: guarda o índice do slot. O item equipado continua ocupando
## o slot dele, e se o item mudar de lugar o equipamento acompanha.

signal inventory_changed
signal equipment_changed(espaco: Espaco, item: Item)
## Sinais antigos, mantidos para quem já escutava a contagem.
signal item_added(item: Item, quantidade: int)
signal item_removed(item: Item, quantidade: int)

const COLUNAS: int = 9
const LINHAS: int = 3
const SLOTS_RAPIDOS: int = 9
const SLOTS_DA_MATRIZ: int = COLUNAS * LINHAS
const TOTAL_DE_SLOTS: int = SLOTS_RAPIDOS + SLOTS_DA_MATRIZ

## O item em uso (na mão) não é um espaço daqui: é o slot rápido selecionado, e quem
## guarda a seleção é o EquipmentManager. Aqui ficam só os equipamentos vestidos.
enum Espaco { ARMADURA, ACESSORIO }

## Que categorias de item cada espaço aceita.
const CATEGORIAS_POR_ESPACO: Dictionary = {
	Espaco.ARMADURA: [Item.Categoria.ARMADURA],
	Espaco.ACESSORIO: [Item.Categoria.ACESSORIO],
}

var slots: Array[PilhaDeItens] = []

## Espaço para índice do slot equipado, ou -1 quando o espaço está vazio.
var _equipados: Dictionary = {
	Espaco.ARMADURA: -1,
	Espaco.ACESSORIO: -1,
}

func _init() -> void:
	slots.resize(TOTAL_DE_SLOTS)

## Guarda o item e devolve quanto não coube. Primeiro completa pilhas do mesmo item,
## depois ocupa o primeiro slot vazio, varrendo a barra rápida antes da matriz, para o
## item novo aparecer à mão como no Minecraft.
func adicionar_item(item: Item, quantidade: int) -> int:
	if item == null or quantidade <= 0:
		return 0
	var restante: int = quantidade
	var entrada: PilhaDeItens = PilhaDeItens.new(item, restante)

	for pilha in slots:
		if pilha != null and pilha.item == item:
			restante = pilha.juntar(entrada)
			if restante == 0:
				break

	for indice in TOTAL_DE_SLOTS:
		if restante == 0:
			break
		if slots[indice] == null:
			var nova: PilhaDeItens = PilhaDeItens.new(item, 0)
			restante = nova.juntar(entrada)
			slots[indice] = nova

	var adicionado: int = quantidade - restante
	if adicionado > 0:
		item_added.emit(item, adicionado)
		inventory_changed.emit()
	return restante

## Tira a quantidade pedida, das últimas pilhas para as primeiras, para esvaziar a
## matriz antes da barra rápida. Não tira nada se não tiver o suficiente.
func remover_item(item: Item, quantidade: int) -> bool:
	if obter_quantidade(item) < quantidade:
		return false
	var restante: int = quantidade
	for indice in range(TOTAL_DE_SLOTS - 1, -1, -1):
		var pilha: PilhaDeItens = slots[indice]
		if pilha == null or pilha.item != item:
			continue
		var tirado: int = mini(pilha.quantidade, restante)
		pilha.quantidade -= tirado
		restante -= tirado
		if pilha.esta_vazia():
			_esvaziar_slot(indice)
		if restante == 0:
			break
	item_removed.emit(item, quantidade)
	inventory_changed.emit()
	return true

func obter_quantidade(item: Item) -> int:
	var total: int = 0
	for pilha in slots:
		if pilha != null and pilha.item == item:
			total += pilha.quantidade
	return total

## Move o conteúdo de um slot para outro. Item igual junta na pilha de destino, item
## diferente troca os dois de lugar. O equipamento acompanha o slot que mudou.
func mover(indice_origem: int, indice_destino: int) -> void:
	if not _indice_valido(indice_origem) or not _indice_valido(indice_destino):
		return
	if indice_origem == indice_destino or slots[indice_origem] == null:
		return
	var origem: PilhaDeItens = slots[indice_origem]
	var destino: PilhaDeItens = slots[indice_destino]

	if destino != null and destino.item == origem.item:
		destino.juntar(origem)
		if origem.esta_vazia():
			_esvaziar_slot(indice_origem)
	else:
		slots[indice_destino] = origem
		slots[indice_origem] = destino
		_trocar_ponteiros_de_equipamento(indice_origem, indice_destino)
	inventory_changed.emit()

func slot_em(indice: int) -> PilhaDeItens:
	if not _indice_valido(indice):
		return null
	return slots[indice]

## Equipa o item do slot no espaço. Recusa slot vazio e item de categoria errada.
func equipar(espaco: Espaco, indice_do_slot: int) -> bool:
	var pilha: PilhaDeItens = slot_em(indice_do_slot)
	if pilha == null or not aceita(espaco, pilha.item):
		return false
	if _equipados[espaco] == indice_do_slot:
		return true
	_equipados[espaco] = indice_do_slot
	equipment_changed.emit(espaco, pilha.item)
	return true

func aceita(espaco: Espaco, item: Item) -> bool:
	return item != null and CATEGORIAS_POR_ESPACO[espaco].has(item.categoria)

func desequipar(espaco: Espaco) -> void:
	if _equipados[espaco] == -1:
		return
	_equipados[espaco] = -1
	equipment_changed.emit(espaco, null)

func item_equipado(espaco: Espaco) -> Item:
	var pilha: PilhaDeItens = slot_em(_equipados[espaco])
	return pilha.item if pilha != null else null

func indice_equipado(espaco: Espaco) -> int:
	return _equipados[espaco]

## Primeiro slot que guarda o item, ou -1.
func indice_do_item(item: Item) -> int:
	for indice in TOTAL_DE_SLOTS:
		if slots[indice] != null and slots[indice].item == item:
			return indice
	return -1

func esta_cheio() -> bool:
	return not slots.has(null)

func _indice_valido(indice: int) -> bool:
	return indice >= 0 and indice < TOTAL_DE_SLOTS

## Slot que ficou vazio deixa de estar equipado em qualquer espaço.
func _esvaziar_slot(indice: int) -> void:
	slots[indice] = null
	for espaco in _equipados:
		if _equipados[espaco] == indice:
			desequipar(espaco)

func _trocar_ponteiros_de_equipamento(indice_a: int, indice_b: int) -> void:
	for espaco in _equipados:
		if _equipados[espaco] == indice_a:
			_equipados[espaco] = indice_b
		elif _equipados[espaco] == indice_b:
			_equipados[espaco] = indice_a
