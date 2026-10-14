class_name ReceitaDeAprimoramento
extends Resource

## O que custa subir um item de um nível para o seguinte: os materiais, com a quantidade
## de cada um, e os créditos.

@export var materiais: Array[Item] = []
## A quantidade de cada material, na mesma ordem de materiais.
@export var quantidades: Array[int] = []
## Créditos fixos da receita.
@export var creditos: int = 0
## Créditos a mais, proporcionais ao valor de venda do item aprimorado. Faz a arma cara
## custar mais para aprimorar que a barata, com a mesma receita.
@export var creditos_por_valor_de_venda: float = 0.0
