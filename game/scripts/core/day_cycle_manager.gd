extends Node

## O relógio do jogo: a hora anda sozinha, o dia vira, e à 1:00 o jogador cai de sono.
##
## O dia vai das 6:00 à 1:00 do dia seguinte. As horas passam de 24 e continuam
## contando (24.5 é 0:30, 25.0 é 1:00), o que evita espalhar conta de virada de meia-noite
## pelo código. Só hora_formatada() precisa saber disso.
##
## Cinco minutos reais de dia e cinco de noite. Como o dia tem 12 horas de jogo e a
## noite tem 7, o relógio anda em duas velocidades. A noite passa mais devagar por hora
## justamente porque é quando o jogador se apressa.
##
## O tempo para sozinho com o menu de pausa aberto, porque este autoload pausa junto com
## a árvore. Para parar fora da pausa (diálogo, no plano 15), use tempo_congelado.

signal day_started(numero_do_dia: int)
signal day_ended(numero_do_dia: int)
## Emitido a cada minuto de jogo, e não a cada quadro, para a interface não redesenhar à toa.
signal hour_changed(hora: float)
signal period_changed(periodo: Periodo)
## forcado é verdadeiro quando o jogador caiu de sono à 1:00, e falso quando foi dormir.
signal player_slept(forcado: bool)

enum Periodo { MADRUGADA, MANHA, TARDE, ANOITECER, NOITE }

const HORA_INICIO_DIA: float = 6.0
const HORA_MEIO_DIA: float = 12.0
const HORA_ANOITECER: float = 18.0
const HORA_NOITE: float = 20.0
const HORA_MEIA_NOITE: float = 24.0
## 1:00 do dia seguinte. Chegando aqui, o jogador cai de sono onde estiver.
const HORA_LIMITE: float = 25.0
const SEGUNDOS_REAIS_DE_DIA: float = 300.0
const SEGUNDOS_REAIS_DE_NOITE: float = 300.0
const SEGUNDOS_REAIS_POR_HORA_DE_DIA: float = SEGUNDOS_REAIS_DE_DIA / (HORA_ANOITECER - HORA_INICIO_DIA)
const SEGUNDOS_REAIS_POR_HORA_DE_NOITE: float = SEGUNDOS_REAIS_DE_NOITE / (HORA_LIMITE - HORA_ANOITECER)

var numero_do_dia: int = 1
var hora_atual: float = HORA_INICIO_DIA
## Para o relógio fora da pausa, por exemplo durante um diálogo.
var tempo_congelado: bool = false

var _minuto_anunciado: int = -1
var _periodo_anunciado: Periodo = Periodo.MANHA
## Entre ir dormir e o dia virar, o relógio não anda nem dispara outro sono.
var _dormindo: bool = false

func _ready() -> void:
	_periodo_anunciado = periodo_atual()

func _process(delta: float) -> void:
	if tempo_congelado or _dormindo or StatusManager.esta_desmaiado:
		return
	var segundos_por_hora: float = SEGUNDOS_REAIS_POR_HORA_DE_DIA if hora_atual < HORA_ANOITECER else SEGUNDOS_REAIS_POR_HORA_DE_NOITE
	hora_atual = minf(hora_atual + delta / segundos_por_hora, HORA_LIMITE)
	_anunciar_mudancas()
	if hora_atual >= HORA_LIMITE:
		dormir(true)

func avancar_para_o_proximo_dia() -> void:
	day_ended.emit(numero_do_dia)
	numero_do_dia += 1
	hora_atual = HORA_INICIO_DIA
	_dormindo = false
	day_started.emit(numero_do_dia)
	_anunciar_mudancas()

## Ir dormir. Na cama (forcado falso), quem cuida da tela é a tela de transição, que
## vira o dia com a tela escura e sem penalidade. À 1:00 (forcado verdadeiro) o jogador
## cai de sono, e é o mesmo caminho do desmaio do plano 07: a mesma tela, a mesma volta
## para casa e a mesma penalidade de acordar com metade da stamina.
func dormir(forcado: bool = false) -> void:
	if _dormindo:
		return
	_dormindo = true
	player_slept.emit(forcado)
	if forcado:
		StatusManager.cair_de_sono()

## Pula o relógio para uma hora do dia atual, entre 6:00 e a 1:00. Serve ao menu de debug
## e a eventos que mudam a hora; a iluminação e o relógio da tela acompanham pelos sinais.
func definir_hora(hora: float) -> void:
	hora_atual = clampf(hora, HORA_INICIO_DIA, HORA_LIMITE - 0.01)
	_anunciar_mudancas()

func periodo_atual() -> Periodo:
	if hora_atual < HORA_INICIO_DIA or hora_atual >= HORA_MEIA_NOITE:
		return Periodo.MADRUGADA
	if hora_atual < HORA_MEIO_DIA:
		return Periodo.MANHA
	if hora_atual < HORA_ANOITECER:
		return Periodo.TARDE
	if hora_atual < HORA_NOITE:
		return Periodo.ANOITECER
	return Periodo.NOITE

## "07:30". A hora passa de 24 depois da meia-noite, e só aqui ela volta para 0.
func hora_formatada() -> String:
	var hora_do_relogio: float = fmod(hora_atual, 24.0)
	var horas: int = int(hora_do_relogio)
	var minutos: int = int((hora_do_relogio - horas) * 60.0)
	return "%02d:%02d" % [horas, minutos]

## 0.0 às 6:00 e 1.0 à 1:00, o limite do dia.
func fracao_do_dia() -> float:
	return clampf((hora_atual - HORA_INICIO_DIA) / (HORA_LIMITE - HORA_INICIO_DIA), 0.0, 1.0)

func _anunciar_mudancas() -> void:
	var minuto: int = int(hora_atual * 60.0)
	if minuto != _minuto_anunciado:
		_minuto_anunciado = minuto
		hour_changed.emit(hora_atual)
	var periodo: Periodo = periodo_atual()
	if periodo != _periodo_anunciado:
		_periodo_anunciado = periodo
		period_changed.emit(periodo)
