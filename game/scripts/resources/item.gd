class_name Item
extends Resource

## Categoria agrupa item para aba de inventário, filtro de loja e regra de presente.
## É enum, e não texto, para um erro de digitação virar erro de compilação.
enum Categoria { RECURSO, SEMENTE, COLHEITA, FERRAMENTA, ARMA, ARMADURA, CONSUMIVEL, MATERIAL, ESPECIAL }

## Chave estável do item, usada em save, em gosto de NPC e em lista de loja. O nome
## é só o texto da tela e pode mudar sem quebrar nada.
@export var id: StringName = &""
@export var nome: String = ""
@export var descricao: String = ""
@export var icone: Texture2D
@export var categoria: Categoria = Categoria.RECURSO
@export var empilhavel: bool = true
@export var quantidade_maxima_por_pilha: int = 99
@export var valor_de_venda: int = 1
@export var pode_ser_presente: bool = true
