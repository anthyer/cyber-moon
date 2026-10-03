class_name Cultivo
extends Resource

## Uma cultura plantável: as texturas de cada estágio, o ritmo de crescimento e o que
## ela rende. O estado de uma planta específica (em que estágio está) não fica aqui,
## fica na GradeSolo: este Resource é o molde, igual para todas as plantas da cultura.

@export var id: StringName = &""
@export var nome: String = ""
## Uma textura por estágio, da muda até a planta madura. O último é o estágio de colher.
@export var estagios_de_crescimento: Array[Texture2D] = []
## A planta que passou um dia em solo seco fica com esta textura até ser arrancada.
@export var textura_murcha: Texture2D
## Dias de solo molhado para passar de um estágio ao seguinte.
@export var dias_por_estagio: int = 2
@export var item_colhido: Item
@export var quantidade_colhida_minima: int = 2
@export var quantidade_colhida_maxima: int = 4
## Ids das estações em que a cultura pode ser plantada e crescer (os de
## SeasonManager.ESTACOES). Vazio vale para qualquer estação.
@export var estacoes_permitidas: Array[StringName] = []
## Quando maior que zero, a planta volta para este estágio ao ser colhida em vez de
## sumir. É o que faz tomate render várias colheitas de um plantio só.
@export var estagio_de_rebrota: int = 0

## Tamanho da planta madura em relação ao padrão. A muda nasce no tamanho padrão e a
## planta cresce até esta escala a cada estágio. Serve para cultura que na vida real é
## alta, como o milho.
@export var escala_da_planta_madura: float = 1.0

func cresce_na_estacao(estacao: StringName) -> bool:
	return estacoes_permitidas.is_empty() or estacoes_permitidas.has(estacao)

func estagio_maduro() -> int:
	return estagios_de_crescimento.size() - 1

## Escala do visual num estágio: 1.0 na muda, subindo por igual até a escala da madura.
func escala_no_estagio(estagio: int) -> float:
	var maduro: int = estagio_maduro()
	if maduro <= 0:
		return escala_da_planta_madura
	return lerpf(1.0, escala_da_planta_madura, clampf(float(estagio) / float(maduro), 0.0, 1.0))
