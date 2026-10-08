class_name Item
extends Resource

## Categoria agrupa item para aba de inventário, filtro de loja e regra de presente.
## É enum, e não texto, para um erro de digitação virar erro de compilação.
## ACESSORIO entrou no fim, e não no meio, porque o .tres grava a categoria como número:
## inserir no meio mudaria a categoria de todos os itens já salvos.
enum Categoria { RECURSO, SEMENTE, COLHEITA, FERRAMENTA, ARMA, ARMADURA, CONSUMIVEL, MATERIAL, ESPECIAL, ACESSORIO }

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
## Preço na loja. Zero usa a regra do EconomyManager (o dobro do valor de venda, ou a
## regra da semente). Preencha só para exceção escrita à mão.
@export var preco_de_compra: int = 0
## Item-chave: de missão, de história, ou qualquer coisa que o jogador não pode perder.
## Não pode ser solto, dado, jogado na lixeira, nem some do chão.
@export var item_chave: bool = false

## Falso para o que o jogador nunca pode perder por conta própria: item-chave, ferramenta
## e arma. É a regra única que soltar, presentear, a lixeira do inventário e o sumiço do
## item no chão consultam, para as quatro coisas nunca discordarem.
func pode_ser_descartado() -> bool:
	return not item_chave and categoria != Categoria.FERRAMENTA and categoria != Categoria.ARMA

## Pode ir para o baú de venda. Arma pode (é como o jogador se livra de uma); ferramenta
## de fazenda nunca, porque ela é melhorada, e não vendida; item-chave nunca. Item sem
## valor também não, para não sumir do baú em troca de nada.
func pode_ser_vendido() -> bool:
	return not item_chave and categoria != Categoria.FERRAMENTA and valor_de_venda > 0

## Pode ir para o baú de guardar. Só o item-chave fica de fora.
func pode_ser_guardado() -> bool:
	return not item_chave
