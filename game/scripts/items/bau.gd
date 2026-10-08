class_name Bau
extends Node3D

## Um baú no mundo. Há dois, com a mesma cena:
##
## - O de guardar tira item do inventário e devolve quando o jogador quiser.
## - O de venda vende tudo que estiver dentro na virada do dia, e o dinheiro vai para a
##   conta do jogador. É como se vende no jogo: sem andar até a loja.
##
## Interagir abre a tela de baú (ver AreaDeInteracao para o contrato de interação). O que
## cada baú aceita segue a tabela do plano 17: item-chave não entra em nenhum, e
## ferramenta de fazenda nunca é vendida.

enum Funcao { GUARDAR, VENDER }

@export var funcao: Funcao = Funcao.GUARDAR
@export var total_de_slots: int = 27

const COR_DA_ETIQUETA_DE_VENDA: Color = Color(1.0, 0.85, 0.2)

@onready var etiqueta: Label3D = $Etiqueta

var conteudo: ContainerDeItens
var nome_exibido: String = "Baú"

func _ready() -> void:
	conteudo = ContainerDeItens.new(total_de_slots)
	add_to_group(SaveManager.GRUPO_DOS_SALVAVEIS)
	if e_de_venda():
		nome_exibido = "Baú de venda"
		# A etiqueta na frente da caixa diz qual é qual, e o de venda ganha outra cor.
		etiqueta.text = "Venda"
		etiqueta.modulate = COR_DA_ETIQUETA_DE_VENDA
		DayCycleManager.day_ended.connect(_ao_terminar_o_dia)

func interagir() -> void:
	EventBus.chest_requested.emit(self)

func e_de_venda() -> bool:
	return funcao == Funcao.VENDER

func aceita(item: Item) -> bool:
	if item == null:
		return false
	return item.pode_ser_vendido() if e_de_venda() else item.pode_ser_guardado()

## Quanto rende o que está no baú agora. Só faz sentido no de venda.
func valor_total() -> int:
	return EconomyManager.valor_de(conteudo.pilhas())

## A virada do dia recolhe o baú de venda, seja ela dormindo na cama, caindo de sono ou
## desmaiando: os três caminhos passam pelo day_ended.
func _ao_terminar_o_dia(_numero_do_dia: int) -> void:
	if conteudo.esta_vazio():
		return
	EconomyManager.vender(conteudo.pilhas())
	conteudo.esvaziar()

# Save

## Cada baú é salvo pelo nome do nó na fase, que precisa ser único entre os baús.
func chave_de_save() -> String:
	return "bau_" + String(name)

func exportar_estado() -> Dictionary:
	return conteudo.exportar_estado()

func importar_estado(dados: Dictionary) -> void:
	conteudo.importar_estado(dados)
