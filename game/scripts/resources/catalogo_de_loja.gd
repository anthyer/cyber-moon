class_name CatalogoDeLoja
extends Resource

## O que um comerciante vende, e quando ele atende.
##
## Um item pode exigir um marco de progressão (GameManager.marcos_desbloqueados) para
## aparecer na loja. É assim que o catálogo cresce conforme o jogador vende.

@export var npc_id: String = ""
@export var itens: Array[Item] = []
## O marco exigido por cada item, na mesma ordem de itens. Texto vazio (ou a lista mais
## curta que a de itens) quer dizer que o item está à venda desde o começo.
@export var marco_necessario: Array[String] = []
@export var hora_de_abrir: float = 9.0
@export var hora_de_fechar: float = 18.0

## Os itens que o jogador já pode comprar.
func itens_disponiveis() -> Array[Item]:
	var lista: Array[Item] = []
	for indice in itens.size():
		var marco: String = marco_necessario[indice] if indice < marco_necessario.size() else ""
		if marco == "" or GameManager.marco_esta_desbloqueado(marco):
			lista.append(itens[indice])
	return lista

func e_folga() -> bool:
	return SeasonManager.dia_da_semana() == SeasonManager.DIA_DE_FOLGA

func esta_no_horario() -> bool:
	return DayCycleManager.hora_atual >= hora_de_abrir and DayCycleManager.hora_atual < hora_de_fechar

## A loja atende no horário comercial, e fecha na Folga.
func esta_aberta() -> bool:
	return not e_folga() and esta_no_horario()
