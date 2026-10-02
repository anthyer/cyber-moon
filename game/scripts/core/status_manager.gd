extends Node

## Vida, stamina, experiência e nível do jogador.
##
## A stamina não volta sozinha: só dormindo (a virada do dia) ou comendo. É isso que dá
## peso à decisão de quantas tarefas fazer no dia. A vida volta devagar quando o
## jogador fica um tempo sem levar dano.
##
## Zerar a stamina ou a vida derruba o jogador. Não existe tela de fim de jogo: perder é
## perder o resto do dia e acordar em casa no dia seguinte com a barra pela metade. O
## máximo não diminui: o que falta pode ser recuperado comendo.

signal health_changed(atual: int, maxima: int)
signal stamina_changed(atual: float, maxima: float)
signal level_changed(novo_nivel: int)
signal experience_changed(atual: int, para_o_proximo: int)
signal player_fainted(motivo: Motivo)
signal player_woke_up(motivo: Motivo)

## SONO é cair de sono à 1:00 (plano 10). A penalidade é a mesma da exaustão.
enum Motivo { EXAUSTAO, FERIMENTO, SONO }

const VIDA_BASE: int = 100
const STAMINA_BASE: float = 100.0
const VIDA_POR_NIVEL: int = 10
const STAMINA_POR_NIVEL: float = 8.0
const NIVEL_MAXIMO: int = 20
## A experiência para subir cresce com o nível: 100 para o 2, 200 para o 3, e assim vai.
const EXPERIENCIA_POR_NIVEL: int = 100

## Com quanto da barra o jogador acorda no dia seguinte a cair. Desmaiar de cansaço
## custa metade da stamina; ser derrotado custa metade da stamina e metade da vida.
const FRACAO_DE_STAMINA_APOS_QUEDA: float = 0.5
const FRACAO_DE_VIDA_APOS_DERROTA: float = 0.5

const SEGUNDOS_SEM_DANO_PARA_REGENERAR: float = 5.0
const VIDA_REGENERADA_POR_SEGUNDO: float = 1.0

var custos: CustosDeAcao = preload("res://resources/status/custos_padrao.tres")

var nivel: int = 1
var experiencia: int = 0
var vida_atual: int = VIDA_BASE
var stamina_atual: float = STAMINA_BASE
## Verdadeiro entre a queda e o acordar. Enquanto vale, nada gasta nem recupera.
var esta_desmaiado: bool = false
## Só para teste, ligado pelo menu de debug: o jogador não perde vida nem cai por dano.
var invencivel_para_teste: bool = false
## Verdadeiro no dia em que o jogador acordou depois de cair, com a barra pela metade.
var desmaiou_ontem: bool = false

var _motivo_da_queda: Motivo = Motivo.EXAUSTAO
var _segundos_desde_o_dano: float = SEGUNDOS_SEM_DANO_PARA_REGENERAR
var _vida_regenerada_acumulada: float = 0.0

func _ready() -> void:
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)

func _process(delta: float) -> void:
	if esta_desmaiado or vida_atual >= vida_maxima():
		return
	_segundos_desde_o_dano += delta
	if _segundos_desde_o_dano < SEGUNDOS_SEM_DANO_PARA_REGENERAR:
		return
	# A vida é inteira e a regeneração por quadro é uma fração, então a fração vai
	# juntando até dar um ponto inteiro.
	_vida_regenerada_acumulada += VIDA_REGENERADA_POR_SEGUNDO * delta
	if _vida_regenerada_acumulada >= 1.0:
		var pontos: int = int(_vida_regenerada_acumulada)
		_vida_regenerada_acumulada -= pontos
		curar(pontos)

func vida_maxima() -> int:
	return VIDA_BASE + VIDA_POR_NIVEL * (nivel - 1)

func stamina_maxima() -> float:
	return STAMINA_BASE + STAMINA_POR_NIVEL * (nivel - 1)

func experiencia_para_o_proximo_nivel() -> int:
	return EXPERIENCIA_POR_NIVEL * nivel

func tem_stamina(quantidade: float) -> bool:
	return not esta_desmaiado and stamina_atual >= quantidade

## Gasta a stamina e retorna true. Retorna false, sem gastar nada, quando não havia o
## bastante: quem chama usa isso para recusar a ação. Chegar a zero derruba o jogador.
func gastar_stamina(quantidade: float) -> bool:
	if not tem_stamina(quantidade):
		return false
	stamina_atual -= quantidade
	stamina_changed.emit(stamina_atual, stamina_maxima())
	if stamina_atual <= 0.0:
		_cair(Motivo.EXAUSTAO)
	return true

func recuperar_stamina(quantidade: float) -> void:
	if esta_desmaiado:
		return
	stamina_atual = minf(stamina_atual + quantidade, stamina_maxima())
	stamina_changed.emit(stamina_atual, stamina_maxima())

## A origem é quem causou o dano. Ainda não é usada; o plano 09 usa para o recuo.
func receber_dano(quantidade: int, _origem: Node3D = null) -> void:
	if esta_desmaiado or quantidade <= 0 or invencivel_para_teste:
		return
	vida_atual = maxi(vida_atual - quantidade, 0)
	_segundos_desde_o_dano = 0.0
	_vida_regenerada_acumulada = 0.0
	health_changed.emit(vida_atual, vida_maxima())
	if vida_atual <= 0:
		_cair(Motivo.FERIMENTO)

func curar(quantidade: int) -> void:
	if esta_desmaiado:
		return
	vida_atual = mini(vida_atual + quantidade, vida_maxima())
	health_changed.emit(vida_atual, vida_maxima())

## Retorna false quando o consumível não faria nada (vida e stamina já cheias), para o
## item não ser gasto à toa.
func consumir(consumivel: Consumivel) -> bool:
	if esta_desmaiado or consumivel == null:
		return false
	var recuperaria_vida: bool = consumivel.recupera_vida > 0 and vida_atual < vida_maxima()
	var recuperaria_stamina: bool = consumivel.recupera_stamina > 0 and stamina_atual < stamina_maxima()
	if not recuperaria_vida and not recuperaria_stamina:
		return false
	curar(consumivel.recupera_vida)
	recuperar_stamina(consumivel.recupera_stamina)
	return true

## Subir de nível aumenta os dois máximos, e o jogador ganha na hora os pontos que o
## máximo cresceu, para subir de nível ser sentido como um alívio.
func ganhar_experiencia(quantidade: int) -> void:
	if quantidade <= 0 or nivel >= NIVEL_MAXIMO:
		return
	experiencia += quantidade
	while nivel < NIVEL_MAXIMO and experiencia >= experiencia_para_o_proximo_nivel():
		experiencia -= experiencia_para_o_proximo_nivel()
		nivel += 1
		vida_atual += VIDA_POR_NIVEL
		stamina_atual += STAMINA_POR_NIVEL
		level_changed.emit(nivel)
		health_changed.emit(vida_atual, vida_maxima())
		stamina_changed.emit(stamina_atual, stamina_maxima())
	if nivel >= NIVEL_MAXIMO:
		experiencia = 0
	experience_changed.emit(experiencia, experiencia_para_o_proximo_nivel())

## Chamado pela tela de desmaio depois de escurecer: vira o dia, o que restaura o status
## já com a penalidade, e avisa que o jogador acordou.
func acordar_no_dia_seguinte() -> void:
	if not esta_desmaiado:
		return
	DayCycleManager.avancar_para_o_proximo_dia()
	esta_desmaiado = false
	player_woke_up.emit(_motivo_da_queda)

## Chamado pelo DayCycleManager quando o relógio chega à 1:00.
func cair_de_sono() -> void:
	_cair(Motivo.SONO)

func _cair(motivo: Motivo) -> void:
	if esta_desmaiado:
		return
	esta_desmaiado = true
	_motivo_da_queda = motivo
	player_fainted.emit(motivo)

## Todo começo de dia restaura o jogador. Se ele caiu no dia anterior, acorda com a
## barra pela metade em vez de cheia; o máximo continua o mesmo.
func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	desmaiou_ontem = esta_desmaiado
	var fracao_de_stamina: float = 1.0
	var fracao_de_vida: float = 1.0
	if esta_desmaiado:
		fracao_de_stamina = FRACAO_DE_STAMINA_APOS_QUEDA
		if _motivo_da_queda == Motivo.FERIMENTO:
			fracao_de_vida = FRACAO_DE_VIDA_APOS_DERROTA
	vida_atual = int(vida_maxima() * fracao_de_vida)
	stamina_atual = stamina_maxima() * fracao_de_stamina
	health_changed.emit(vida_atual, vida_maxima())
	stamina_changed.emit(stamina_atual, stamina_maxima())
