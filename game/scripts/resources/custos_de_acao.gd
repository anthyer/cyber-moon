class_name CustosDeAcao
extends Resource

## Quanto de stamina cada ação do jogador gasta e quanta experiência ela dá.
##
## Fica num Resource, e não espalhado pelo código, para o balanceamento ser feito num
## arquivo só (resources/status/custos_padrao.tres). O custo de cada ferramenta não está
## aqui: fica no .tres da própria ferramenta, porque ferramenta nova traz o custo dela.
##
## A referência de balanceamento: 100 de stamina deve dar para arar, molhar e plantar
## uns 15 quadrados e ainda sobrar para explorar.

@export_group("Fazenda")
@export var stamina_plantar: float = 0.5
@export var experiencia_plantar: int = 1
@export var stamina_colher: float = 1.0
@export var experiencia_colher: int = 3

@export_group("Combate")
## Cobrado só quando o golpe acerta um oponente. Golpe no ar não custa nada, e o dash
## também não gasta stamina.
@export var stamina_golpe_que_acerta: float = 1.0
