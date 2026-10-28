class_name Vendinha
extends Node3D

## A vendinha da demo: uma barraca fixa na cidade, no lugar dos comerciantes.
##
## No jogo completo quem vende é um NPC, e a loja só abre na conversa com ele. A demo não
## tem NPC, então a barraca faz as duas coisas sozinha: o balcão abre a loja para comprar,
## e o baú de venda ao lado compra do jogador na hora em que a tela dele fecha.
##
## O que a barraca vende é um CatalogoDeLoja num .tres, como o dos comerciantes. Ela
## atende a qualquer hora: o horário do catálogo não é consultado.

@export var nome_da_loja: String = "Vendinha"
@export var catalogo: CatalogoDeLoja

@onready var _modelo: Node3D = $Modelo

func interagir() -> void:
	EventBus.shop_requested.emit(nome_da_loja, catalogo)

func texto_de_interacao() -> String:
	return "Comprar na %s" % nome_da_loja.to_lower()

## O destaque brilha a barraca inteira, e não só a área invisível do balcão.
func no_do_destaque() -> Node3D:
	return _modelo
