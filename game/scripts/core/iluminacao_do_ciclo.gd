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
##
## A estação (plano 11) ajusta por cima: tinge a cor do sol, multiplica a energia e muda a
## hora do pôr do sol. A tabela foi escrita para o anoitecer às 18:00; os pontos do fim
## da tarde em diante andam junto com o anoitecer da estação, e o resto fica igual.

@export var caminho_da_luz: NodePath = ^"../Luz"
@export var caminho_do_ambiente: NodePath = ^"../Ambiente"

## Hora, cor do sol, energia do sol, energia do ambiente, energia do céu, altura do sol
## em graus acima do horizonte. Ponto de partida do plano 10, ajustado olhando o jogo.
## Escrita para o anoitecer padrão, às 18:00.
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

## Pontos a partir desta hora andam junto com o anoitecer da estação. O das 15:00 fica
## parado, a não ser que o anoitecer chegue perto dele.
const HORA_DA_TABELA_QUE_ACOMPANHA_O_ANOITECER: float = DayCycleManager.HORA_ANOITECER
## Folga mínima entre o ponto das 15:00 e o anoitecer, para a tarde não escurecer de uma vez.
const FOLGA_ANTES_DO_ANOITECER: float = 1.5

@onready var _luz: DirectionalLight3D = get_node(caminho_da_luz)
@onready var _ambiente: WorldEnvironment = get_node(caminho_do_ambiente)

func _ready() -> void:
	DayCycleManager.hour_changed.connect(_aplicar_hora)
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	_aplicar_hora(DayCycleManager.hora_atual)

func _ao_mudar_estacao(_nova: StringName) -> void:
	_aplicar_hora(DayCycleManager.hora_atual)

func _aplicar_hora(hora: float) -> void:
	var estacao: PerfilEstacao = SeasonManager.perfil_atual()
	var anoitecer: float = estacao.hora_do_anoitecer
	var pontos: Array = _pontos_da_estacao(anoitecer)
	var anterior: Array = pontos[0]
	var seguinte: Array = pontos[pontos.size() - 1]
	for indice in pontos.size() - 1:
		if hora >= pontos[indice][0] and hora <= pontos[indice + 1][0]:
			anterior = pontos[indice]
			seguinte = pontos[indice + 1]
			break
	var peso: float = 0.0
	if seguinte[0] > anterior[0]:
		peso = clampf((hora - anterior[0]) / (seguinte[0] - anterior[0]), 0.0, 1.0)

	_luz.light_color = (anterior[1] as Color).lerp(seguinte[1], peso) * estacao.cor_da_luz
	_luz.light_energy = lerpf(anterior[2], seguinte[2], peso) * estacao.multiplicador_de_energia
	var ambiente: Environment = _ambiente.environment
	ambiente.ambient_light_energy = lerpf(anterior[3], seguinte[3], peso) * estacao.multiplicador_de_energia
	ambiente.background_energy_multiplier = lerpf(anterior[4], seguinte[4], peso)

	var altura_do_sol: float = lerpf(anterior[5], seguinte[5], peso)
	var direcao: float = DIRECAO_DO_POR
	if hora < anoitecer:
		var fracao_do_sol: float = (hora - DayCycleManager.HORA_INICIO_DIA) / (anoitecer - DayCycleManager.HORA_INICIO_DIA)
		direcao = lerpf(DIRECAO_DO_NASCER, DIRECAO_DO_POR, fracao_do_sol)
	_luz.rotation_degrees = Vector3(-altura_do_sol, direcao, 0.0)

## A tabela com os pontos do fim do dia deslocados para o anoitecer da estação. Com o
## anoitecer às 16:30, o ponto das 18:00 vira 16:30 e o das 20:00 vira 18:30. O último
## ponto, o da 1:00, não anda, porque é o fim do dia de qualquer estação.
func _pontos_da_estacao(anoitecer: float) -> Array:
	var deslocamento: float = anoitecer - HORA_DA_TABELA_QUE_ACOMPANHA_O_ANOITECER
	var ultimo: int = PONTOS_POR_HORA.size() - 1
	var pontos: Array = []
	for indice in PONTOS_POR_HORA.size():
		var ponto: Array = (PONTOS_POR_HORA[indice] as Array).duplicate()
		var hora_do_ponto: float = ponto[0]
		if indice != ultimo and hora_do_ponto >= HORA_DA_TABELA_QUE_ACOMPANHA_O_ANOITECER:
			ponto[0] = hora_do_ponto + deslocamento
		elif indice != ultimo and hora_do_ponto > DayCycleManager.HORA_INICIO_DIA:
			ponto[0] = minf(hora_do_ponto, anoitecer - FOLGA_ANTES_DO_ANOITECER)
		pontos.append(ponto)
	return pontos
