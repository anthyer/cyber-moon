class_name FaixasDeMaterial
extends Resource

## Os materiais que os inimigos soltam, separados em três faixas de raridade. O perfil de
## cada inimigo diz a chance de soltar de cada faixa, e o item é sorteado dentro dela.

enum Faixa { COMUM, INCOMUM, RARO }

@export var comuns: Array[Item] = []
@export var incomuns: Array[Item] = []
@export var raros: Array[Item] = []
## A cor do brilho que avisa que caiu um material incomum ou raro.
@export var cor_do_incomum: Color = Color(0.3, 0.95, 1.0)
@export var cor_do_raro: Color = Color(1.0, 0.75, 0.2)

func itens_da_faixa(faixa: Faixa) -> Array[Item]:
	match faixa:
		Faixa.INCOMUM:
			return incomuns
		Faixa.RARO:
			return raros
	return comuns

func cor_da_faixa(faixa: Faixa) -> Color:
	return cor_do_raro if faixa == Faixa.RARO else cor_do_incomum
