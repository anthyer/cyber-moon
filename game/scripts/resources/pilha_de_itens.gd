class_name PilhaDeItens
extends Resource

## Um slot ocupado do inventário: um item e quantas unidades dele. Slot vazio é null no
## array do InventoryManager, nunca uma pilha com quantidade zero.

@export var item: Item
@export var quantidade: int = 0

func _init(item_inicial: Item = null, quantidade_inicial: int = 0) -> void:
	item = item_inicial
	quantidade = quantidade_inicial

func esta_vazia() -> bool:
	return item == null or quantidade <= 0

## Quantas unidades do mesmo item ainda cabem nesta pilha.
func espaco_livre() -> int:
	if item == null:
		return 0
	var limite: int = item.quantidade_maxima_por_pilha if item.empilhavel else 1
	return maxi(limite - quantidade, 0)

## Junta o que couber da outra pilha nesta e devolve o que sobrou nela. Só junta item
## igual; com item diferente não mexe em nada e devolve a quantidade inteira da outra.
func juntar(outra: PilhaDeItens) -> int:
	if outra == null or outra.esta_vazia():
		return 0
	if outra.item != item:
		return outra.quantidade
	var movido: int = mini(espaco_livre(), outra.quantidade)
	quantidade += movido
	outra.quantidade -= movido
	return outra.quantidade
