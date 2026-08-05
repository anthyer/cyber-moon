extends Node

signal item_added(item: Item, quantidade: int)
signal item_removed(item: Item, quantidade: int)

var pilhas: Dictionary = {}

func adicionar_item(item: Item, quantidade: int) -> void:
	var quantidade_atual: int = pilhas.get(item, 0)
	pilhas[item] = quantidade_atual + quantidade
	item_added.emit(item, quantidade)

func remover_item(item: Item, quantidade: int) -> bool:
	var quantidade_atual: int = pilhas.get(item, 0)
	if quantidade_atual < quantidade:
		return false
	pilhas[item] = quantidade_atual - quantidade
	item_removed.emit(item, quantidade)
	return true

func obter_quantidade(item: Item) -> int:
	return pilhas.get(item, 0)
