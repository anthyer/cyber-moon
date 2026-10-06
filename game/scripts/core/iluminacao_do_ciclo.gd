class_name IluminacaoDoCiclo
extends Node

## Faz a luz da cena acompanhar a hora do DayCycleManager: a cor e a força do sol, o
## ângulo dele cruzando o céu, e o quanto o céu e o ambiente clareiam a cena. A cor e a
## força mudam a cada quadro; o ângulo, que move a sombra, muda em degraus (veja
## horas_por_passo_da_sombra).
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

## A sombra não anda o tempo todo: o dia é dividido em trechos deste tamanho, em horas de
## jogo, e a direção do sol fica parada dentro de cada um. Sombra se arrastando devagar o
## dia inteiro treme na borda e distrai; parada, ela fica nítida.
@export var horas_por_passo_da_sombra: float = 2.0
## Segundos reais que o sol leva para girar de um trecho para o seguinte.
@export var segundos_da_troca_de_sombra: float = 3.0

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

## A tabela já deslocada para a estação atual. Só é refeita quando a estação muda, porque
## a luz é aplicada a cada quadro.
var _estacao: PerfilEstacao
var _pontos: Array = []
## Começo do trecho do dia em que a sombra está parada agora. Negativo força a primeira
## aplicação.
## O clima do dia (plano 13): escurece e tinge por cima da estação, e liga a névoa.
var _clima: PerfilClima
## Multiplicador extra do clarão do raio. Vale 1 fora do clarão.
var _clarao: float = 1.0
var _animacao_do_clarao: Tween
var _trecho_da_sombra: float = -1.0
var _troca_de_sombra: Tween

func _ready() -> void:
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	# O clima primeiro, porque aplicar a estação já calcula a luz com os dois.
	_ao_mudar_clima(WeatherManager.clima_atual)
	_ao_mudar_estacao(SeasonManager.estacao_atual())

## A cor e a força da luz andam a cada quadro, para a cena clarear e escurecer sem degrau.
## A direção do sol, que é o que move a sombra, não: ela fica parada por um trecho do dia
## e só troca na virada do trecho.
func _process(_delta: float) -> void:
	_aplicar_hora(DayCycleManager.hora_atual)

func _ao_mudar_estacao(_nova: StringName) -> void:
	_estacao = SeasonManager.perfil_atual()
	_pontos = _pontos_da_estacao(_estacao.hora_do_anoitecer)
	_aplicar_hora(DayCycleManager.hora_atual)
	_posicionar_o_sol(DayCycleManager.hora_atual, false)

## A névoa não depende da hora, então só é mexida quando o clima muda.
func _ao_mudar_clima(_novo: StringName) -> void:
	_clima = WeatherManager.perfil_atual()
	var ambiente: Environment = _ambiente.environment
	ambiente.fog_enabled = _clima.densidade_da_nevoa > 0.0
	ambiente.fog_density = _clima.densidade_da_nevoa
	ambiente.fog_light_color = _clima.cor_da_nevoa
	# Céu fechado espalha a luz, então a sombra do sol fica fraca e de borda borrada.
	_luz.shadow_opacity = _clima.opacidade_da_sombra
	_luz.shadow_blur = _clima.desfoque_da_sombra

## O clarão do raio: a luz sobe muito de uma vez e volta em duracao segundos.
func dar_clarao(intensidade: float = 6.0, duracao: float = 0.25) -> void:
	if _animacao_do_clarao != null:
		_animacao_do_clarao.kill()
	_clarao = intensidade
	_animacao_do_clarao = create_tween()
	_animacao_do_clarao.tween_property(self, "_clarao", 1.0, duracao)

## De um dia para o outro o sol volta do poente para o nascente. Esse giro não é uma troca
## de trecho, então a sombra pula direto, sem a transição.
func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	_posicionar_o_sol(DayCycleManager.hora_atual, false)

func _aplicar_hora(hora: float) -> void:
	var amostra: Array = _amostrar(hora)
	var energia: float = _estacao.multiplicador_de_energia * _clima.multiplicador_de_energia * _clarao
	_luz.light_color = (amostra[1] as Color) * _estacao.cor_da_luz * _clima.cor_da_luz
	_luz.light_energy = amostra[2] * energia
	var ambiente: Environment = _ambiente.environment
	ambiente.ambient_light_energy = amostra[3] * energia
	ambiente.background_energy_multiplier = amostra[4] * _clima.multiplicador_de_energia * _clarao

	if _trecho_de(hora) != _trecho_da_sombra:
		_posicionar_o_sol(hora, _trecho_da_sombra >= 0.0)

## Põe o sol na posição do trecho do dia em que a hora cai. Com suave, ele gira até lá em
## segundos_da_troca_de_sombra; sem, pula direto.
func _posicionar_o_sol(hora: float, suave: bool) -> void:
	_trecho_da_sombra = _trecho_de(hora)
	var rotacao: Vector3 = _rotacao_do_sol(_trecho_da_sombra)
	if _troca_de_sombra != null:
		_troca_de_sombra.kill()
	if not suave or segundos_da_troca_de_sombra <= 0.0:
		_luz.rotation_degrees = rotacao
		return
	_troca_de_sombra = create_tween()
	_troca_de_sombra.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_troca_de_sombra.tween_property(_luz, "rotation_degrees", rotacao, segundos_da_troca_de_sombra)

## A hora em que começa o trecho que contém a hora dada. Com passo de 2 horas, os trechos
## começam às 6:00, 8:00, 10:00 e assim por diante.
func _trecho_de(hora: float) -> float:
	var desde_o_inicio: float = maxf(hora - DayCycleManager.HORA_INICIO_DIA, 0.0)
	return DayCycleManager.HORA_INICIO_DIA + floorf(desde_o_inicio / horas_por_passo_da_sombra) * horas_por_passo_da_sombra

## A rotação da luz durante um trecho. Usa a hora do meio do trecho, e não a do começo:
## assim a sombra representa o trecho inteiro, e o primeiro trecho da manhã não passa duas
## horas com a sombra rasteira das 6:00.
func _rotacao_do_sol(inicio_do_trecho: float) -> Vector3:
	var hora: float = minf(inicio_do_trecho + horas_por_passo_da_sombra * 0.5, DayCycleManager.HORA_LIMITE)
	var anoitecer: float = _estacao.hora_do_anoitecer
	var altura_do_sol: float = _amostrar(hora)[5]
	var direcao: float = DIRECAO_DO_POR
	if hora < anoitecer:
		var fracao_do_sol: float = (hora - DayCycleManager.HORA_INICIO_DIA) / (anoitecer - DayCycleManager.HORA_INICIO_DIA)
		direcao = lerpf(DIRECAO_DO_NASCER, DIRECAO_DO_POR, fracao_do_sol)
	return Vector3(-altura_do_sol, direcao, 0.0)

## Os valores da tabela numa hora qualquer, interpolados entre os dois pontos vizinhos, no
## mesmo formato de uma linha da tabela.
func _amostrar(hora: float) -> Array:
	var anterior: Array = _pontos[0]
	var seguinte: Array = _pontos[_pontos.size() - 1]
	for indice in _pontos.size() - 1:
		if hora >= _pontos[indice][0] and hora <= _pontos[indice + 1][0]:
			anterior = _pontos[indice]
			seguinte = _pontos[indice + 1]
			break
	var peso: float = 0.0
	if seguinte[0] > anterior[0]:
		peso = clampf((hora - anterior[0]) / (seguinte[0] - anterior[0]), 0.0, 1.0)
	return [
		hora,
		(anterior[1] as Color).lerp(seguinte[1], peso),
		lerpf(anterior[2], seguinte[2], peso),
		lerpf(anterior[3], seguinte[3], peso),
		lerpf(anterior[4], seguinte[4], peso),
		lerpf(anterior[5], seguinte[5], peso),
	]

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
