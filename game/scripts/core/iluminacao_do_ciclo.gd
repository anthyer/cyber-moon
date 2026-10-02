class_name IluminacaoDoCiclo
extends Node

## Faz a luz da cena acompanhar a hora do DayCycleManager: a cor e a força do sol, o
## ângulo dele cruzando o céu, e o quanto o céu e o ambiente clareiam a cena.
##
## Os valores vêm de uma tabela de pontos por hora, e entre dois pontos a luz é
## interpolada, para a cena escurecer e clarear aos poucos e não em salto. A energia
## nunca chega a zero: noite toda preta é frustrante, e o padrão do gênero é uma noite
## azulada em que ainda dá para se orientar.
##
## A luz é girada por código, com rotation_degrees, e não pela matriz escrita à mão no
## .tscn, porque os 9 números do Transform3D no arquivo são as linhas da matriz e já
## fizeram a luz apontar para o céu neste projeto.

@export var caminho_da_luz: NodePath = ^"../Luz"
@export var caminho_do_ambiente: NodePath = ^"../Ambiente"

## Hora, cor do sol, energia do sol, energia do ambiente, energia do céu, altura do sol
## em graus acima do horizonte. Ponto de partida do plano 10, ajustado olhando o jogo.
const PONTOS_POR_HORA: Array = [
	[6.0, Color(1.0, 0.62, 0.38), 0.45, 0.45, 0.45, 12.0],
	[9.0, Color(1.0, 0.95, 0.86), 1.0, 1.0, 1.0, 45.0],
	[15.0, Color(1.0, 1.0, 1.0), 1.0, 1.0, 1.0, 50.0],
	[18.0, Color(1.0, 0.58, 0.32), 0.7, 0.65, 0.6, 15.0],
	[20.0, Color(0.38, 0.46, 0.85), 0.18, 0.3, 0.18, 40.0],
	[25.0, Color(0.28, 0.34, 0.72), 0.12, 0.22, 0.08, 40.0],
]

## O sol nasce no leste e se põe no oeste. À noite a luz direcional faz o papel da lua e
## fica parada, vindo do alto.
const DIRECAO_DO_NASCER: float = 90.0
const DIRECAO_DO_POR: float = -90.0

@onready var _luz: DirectionalLight3D = get_node(caminho_da_luz)
@onready var _ambiente: WorldEnvironment = get_node(caminho_do_ambiente)

func _ready() -> void:
	DayCycleManager.hour_changed.connect(_aplicar_hora)
	_aplicar_hora(DayCycleManager.hora_atual)

func _aplicar_hora(hora: float) -> void:
	var anterior: Array = PONTOS_POR_HORA[0]
	var seguinte: Array = PONTOS_POR_HORA[PONTOS_POR_HORA.size() - 1]
	for indice in PONTOS_POR_HORA.size() - 1:
		if hora >= PONTOS_POR_HORA[indice][0] and hora <= PONTOS_POR_HORA[indice + 1][0]:
			anterior = PONTOS_POR_HORA[indice]
			seguinte = PONTOS_POR_HORA[indice + 1]
			break
	var peso: float = 0.0
	if seguinte[0] > anterior[0]:
		peso = clampf((hora - anterior[0]) / (seguinte[0] - anterior[0]), 0.0, 1.0)

	_luz.light_color = (anterior[1] as Color).lerp(seguinte[1], peso)
	_luz.light_energy = lerpf(anterior[2], seguinte[2], peso)
	var ambiente: Environment = _ambiente.environment
	ambiente.ambient_light_energy = lerpf(anterior[3], seguinte[3], peso)
	ambiente.background_energy_multiplier = lerpf(anterior[4], seguinte[4], peso)

	var altura_do_sol: float = lerpf(anterior[5], seguinte[5], peso)
	var direcao: float = DIRECAO_DO_POR
	if hora < DayCycleManager.HORA_ANOITECER:
		var fracao_do_sol: float = (hora - DayCycleManager.HORA_INICIO_DIA) / (DayCycleManager.HORA_ANOITECER - DayCycleManager.HORA_INICIO_DIA)
		direcao = lerpf(DIRECAO_DO_NASCER, DIRECAO_DO_POR, fracao_do_sol)
	_luz.rotation_degrees = Vector3(-altura_do_sol, direcao, 0.0)
