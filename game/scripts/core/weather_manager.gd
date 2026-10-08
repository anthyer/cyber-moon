extends Node

## O clima do dia: sol, chuva ou tempestade.
##
## É sorteado quando o dia começa e não muda no meio. O valor da chuva para o jogador é
## economizar a rega do dia, e para isso ela precisa ser previsível desde o amanhecer.
## A chance de chuva vem do perfil da estação, e a tempestade é um quinto dela.
##
## O clima de amanhã é sorteado junto. Nada usa ainda; existe para a previsão do tempo
## ficar barata de fazer depois.

signal weather_changed(clima: StringName)

const CLIMAS: Array[StringName] = [&"sol", &"chuva", &"tempestade"]
const PASTA_DOS_PERFIS: String = "res://resources/climas/"
## A tempestade é rara: a chance dela é a da chuva dividida por este número.
const DIVISOR_DA_TEMPESTADE: float = 5.0

## O primeiro dia do jogo é sempre de sol.
var clima_atual: StringName = &"sol"
var clima_de_amanha: StringName = &"sol"

var _perfis: Dictionary[StringName, PerfilClima] = {}

func _ready() -> void:
	for clima in CLIMAS:
		_perfis[clima] = load(PASTA_DOS_PERFIS + String(clima) + ".tres") as PerfilClima
	clima_de_amanha = sortear_clima_do_dia(DayCycleManager.numero_do_dia + 1)
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)

## Verdadeiro para chuva e para tempestade.
func esta_chovendo() -> bool:
	return perfil_atual().molha_o_solo

func perfil_do_clima(clima: StringName) -> PerfilClima:
	return _perfis.get(clima, null)

func perfil_atual() -> PerfilClima:
	return perfil_do_clima(clima_atual)

## Sorteia o clima de um dia, com a chance de chuva da estação em que esse dia cai.
func sortear_clima_do_dia(numero_do_dia: int) -> StringName:
	var estacao: PerfilEstacao = SeasonManager.perfil_da_estacao(SeasonManager.estacao_do_dia(numero_do_dia))
	var chance_de_chuva: float = estacao.chance_de_chuva
	var chance_de_tempestade: float = chance_de_chuva / DIVISOR_DA_TEMPESTADE
	var sorteio: float = randf()
	if sorteio < chance_de_tempestade:
		return &"tempestade"
	if sorteio < chance_de_tempestade + chance_de_chuva:
		return &"chuva"
	return &"sol"

## Troca o clima na hora. Serve ao menu de debug e a eventos que forçam um clima.
func definir_clima(clima: StringName) -> void:
	if not _perfis.has(clima) or clima == clima_atual:
		return
	clima_atual = clima
	_anunciar()

## O clima de hoje é o que ontem estava previsto para amanhã, e um novo amanhã é sorteado.
## O sinal sai todo dia, mesmo se o clima repetir, porque quem escuta (a GradeSolo molhando
## o solo) precisa agir a cada amanhecer chuvoso.
func _ao_comecar_o_dia(numero_do_dia: int) -> void:
	clima_atual = clima_de_amanha
	clima_de_amanha = sortear_clima_do_dia(numero_do_dia + 1)
	_anunciar()

func _anunciar() -> void:
	weather_changed.emit(clima_atual)
	EventBus.ambience_requested.emit(perfil_atual().som_ambiente)

# Save

func exportar_estado() -> Dictionary:
	return {"clima_atual": String(clima_atual), "clima_de_amanha": String(clima_de_amanha)}

func importar_estado(dados: Dictionary) -> void:
	var atual: StringName = StringName(dados.get("clima_atual", "sol"))
	var amanha: StringName = StringName(dados.get("clima_de_amanha", "sol"))
	clima_atual = atual if _perfis.has(atual) else &"sol"
	clima_de_amanha = amanha if _perfis.has(amanha) else &"sol"
	_anunciar()
