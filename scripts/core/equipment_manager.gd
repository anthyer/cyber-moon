extends Node

signal tool_equipped(ferramenta: Ferramenta)

# Este @export nao tem efeito em runtime: este autoload eh registrado como
# script puro (nao cena), entao nao existe Inspector pra editar esse array.
# Na pratica ele funciona como uma constante populada pelos preload() abaixo.
@export var ferramentas: Array[Ferramenta] = [
	preload("res://resources/items/enxada.tres"),
	preload("res://resources/items/regador.tres"),
	preload("res://resources/items/picareta.tres"),
]
var indice_atual: int = -1

func equipar_indice(indice: int) -> void:
	if indice < -1 or indice >= ferramentas.size():
		return
	indice_atual = indice
	tool_equipped.emit(ferramenta_atual())

func ciclar(direcao: int) -> void:
	var total: int = ferramentas.size() + 1
	var posicao: int = indice_atual + 1
	posicao = (posicao + direcao + total) % total
	equipar_indice(posicao - 1)

func ferramenta_atual() -> Ferramenta:
	return ferramentas[indice_atual] if indice_atual >= 0 else null
