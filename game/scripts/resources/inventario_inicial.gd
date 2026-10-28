class_name InventarioInicial
extends Resource

## O que o jogador tem ao começar um jogo novo: os itens, na ordem em que entram na barra
## rápida, e os créditos. Na demo é o pacote de teste: todas as armas e ferramentas,
## sementes da estação, comida e um pouco de cada material.

@export var itens: Array[Item] = []
## A quantidade de cada item, na mesma ordem de itens.
@export var quantidades: Array[int] = []
@export var creditos: int = 500
