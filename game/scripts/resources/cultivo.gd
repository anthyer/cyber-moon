class_name Cultivo
extends Resource

## Uma cultura plantável: as texturas de cada estágio, o ritmo de crescimento e o que
## ela rende. O estado de uma planta específica (em que estágio está) não fica aqui,
## fica na GradeSolo: este Resource é o molde, igual para todas as plantas da cultura.

@export var id: StringName = &""
@export var nome: String = ""
## Uma textura por estágio, da muda até a planta madura. O último é o estágio de colher.
@export var estagios_de_crescimento: Array[Texture2D] = []
## Sem uso até o plano 11, que murcha o que está fora da estação.
@export var textura_murcha: Texture2D
## Dias para passar de um estágio ao seguinte com o solo molhado. Com o solo seco leva
## o dobro.
@export var dias_por_estagio: int = 2
@export var item_colhido: Item
@export var quantidade_colhida_minima: int = 1
@export var quantidade_colhida_maxima: int = 2
## Vazio vale para qualquer estação. A checagem entra no plano 11.
@export var estacoes_permitidas: Array[StringName] = []
## Quando maior que zero, a planta volta para este estágio ao ser colhida em vez de
## sumir. É o que faz tomate render várias colheitas de um plantio só.
@export var estagio_de_rebrota: int = 0

func estagio_maduro() -> int:
	return estagios_de_crescimento.size() - 1
