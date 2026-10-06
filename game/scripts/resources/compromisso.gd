class_name Compromisso
extends Resource

## Um item da rotina de um NPC: entre tal e tal hora, se as condições baterem, ele vai
## para tal lugar e fica fazendo tal coisa.
##
## Condição vazia vale para todas. Quando mais de um compromisso serve para o momento,
## vence o mais específico (o que tem mais condições preenchidas), para uma regra geral
## ("de manhã, na praça") conviver com uma exceção ("no aniversário, em casa").

const PESO_DO_ANIVERSARIO: int = 4

## Horas no relógio do jogo, que passa de 24 (25.0 é 1:00). Vale de hora_inicial até
## antes de hora_final.
@export var hora_inicial: float = 8.0
@export var hora_final: float = 12.0
## Ids de SeasonManager.ESTACOES.
@export var estacoes: Array[StringName] = []
## 0 a 5, como SeasonManager.dia_da_semana(). 5 é a Folga.
@export var dias_da_semana: Array[int] = []
## Ids de WeatherManager.CLIMAS.
@export var climas: Array[StringName] = []
@export var apenas_no_aniversario: bool = false

## Nome do Marker3D da fase para onde o NPC vai (filho do nó PontosDeRotina).
@export var destino: StringName = &""
## Animação tocada ao chegar: idle, sit, crouch ou interact-left.
@export var animacao_parado: StringName = &"idle"

func serve_para(hora: float, estacao: StringName, dia_da_semana: int, clima: StringName, e_aniversario: bool) -> bool:
	if hora < hora_inicial or hora >= hora_final:
		return false
	if not estacoes.is_empty() and not estacoes.has(estacao):
		return false
	if not dias_da_semana.is_empty() and not dias_da_semana.has(dia_da_semana):
		return false
	if not climas.is_empty() and not climas.has(clima):
		return false
	if apenas_no_aniversario and not e_aniversario:
		return false
	return true

## Quantas condições, além da hora, este compromisso exige.
func especificidade() -> int:
	var total: int = 0
	if not estacoes.is_empty():
		total += 1
	if not dias_da_semana.is_empty():
		total += 1
	if not climas.is_empty():
		total += 1
	# O aniversário pesa mais que qualquer outra condição sozinha: é um dia só no ano, e
	# precisa vencer a exceção de estação ou de clima que também sirva para o dia.
	if apenas_no_aniversario:
		total += PESO_DO_ANIVERSARIO
	return total
