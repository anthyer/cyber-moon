extends Node

## O calendário: quatro estações de 30 dias, 120 dias por ano.
##
## A estação não é guardada, é calculada do numero_do_dia do DayCycleManager toda vez que
## alguém pergunta. Um número só é a fonte da verdade, e não tem como a estação e o dia
## ficarem dessincronizados. Também não importa quem recebe o day_started primeiro: quem
## perguntar já recebe o valor do dia novo.

## Emitido no começo do primeiro dia de uma estação nova.
signal season_changed(nova: StringName)
## Emitido no começo do primeiro dia de um ano novo, depois do season_changed.
signal year_changed(novo_ano: int)

const DIAS_POR_ESTACAO: int = 30
const ESTACOES: Array[StringName] = [&"brotacao", &"estiagem", &"colheita", &"apagao"]
## A semana do jogo tem 6 dias, e não 7: com 30 dias por estação, o mês fecha em 5
## semanas certinhas. O último dia é a Folga, quando as lojas fecham.
const DIAS_POR_SEMANA: int = 6
const NOMES_DOS_DIAS_DA_SEMANA: Array[String] = ["Primeiro", "Segundo", "Terceiro", "Quarto", "Quinto", "Folga"]
const DIA_DE_FOLGA: int = 5
const PASTA_DOS_PERFIS: String = "res://resources/estacoes/"

var _perfis: Dictionary[StringName, PerfilEstacao] = {}
## Guardados só para saber, na virada do dia, se a estação ou o ano mudou.
var _indice_anunciado: int = 0
var _ano_anunciado: int = 1

func _ready() -> void:
	for estacao in ESTACOES:
		_perfis[estacao] = load(PASTA_DOS_PERFIS + String(estacao) + ".tres") as PerfilEstacao
	_indice_anunciado = indice_da_estacao()
	_ano_anunciado = ano_atual()
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)

## 0 a 3, na ordem de ESTACOES.
func indice_da_estacao() -> int:
	return int(_dias_passados() / DIAS_POR_ESTACAO) % ESTACOES.size()

func estacao_atual() -> StringName:
	return ESTACOES[indice_da_estacao()]

## A estação em que cai um dia qualquer, por exemplo o de amanhã.
func estacao_do_dia(numero_do_dia: int) -> StringName:
	return ESTACOES[int((numero_do_dia - 1) / DIAS_POR_ESTACAO) % ESTACOES.size()]

## 1 a 30.
func dia_da_estacao() -> int:
	return _dias_passados() % DIAS_POR_ESTACAO + 1

## 0 a 5, onde 5 é a Folga. Toda estação começa num Primeiro.
func dia_da_semana() -> int:
	return (dia_da_estacao() - 1) % DIAS_POR_SEMANA

func nome_do_dia_da_semana() -> String:
	return NOMES_DOS_DIAS_DA_SEMANA[dia_da_semana()]

## Começa em 1.
func ano_atual() -> int:
	return int(_dias_passados() / (DIAS_POR_ESTACAO * ESTACOES.size())) + 1

func perfil_da_estacao(estacao: StringName) -> PerfilEstacao:
	return _perfis.get(estacao, null)

func perfil_atual() -> PerfilEstacao:
	return perfil_da_estacao(estacao_atual())

func nome_exibido(estacao: StringName) -> String:
	var perfil: PerfilEstacao = perfil_da_estacao(estacao)
	return perfil.nome_exibido if perfil != null else String(estacao)

## Quantos dias faltam para o primeiro dia da próxima estação. Usado pelo menu de debug.
func dias_ate_a_proxima_estacao() -> int:
	return DIAS_POR_ESTACAO - dia_da_estacao() + 1

## O dia 1 é o primeiro dia do jogo, então zero dias se passaram nele.
func _dias_passados() -> int:
	return DayCycleManager.numero_do_dia - 1

func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	var indice: int = indice_da_estacao()
	if indice != _indice_anunciado:
		_indice_anunciado = indice
		season_changed.emit(estacao_atual())
		var perfil: PerfilEstacao = perfil_atual()
		if perfil != null and perfil.musica != null:
			EventBus.musica_solicitada.emit(perfil.musica)
	var ano: int = ano_atual()
	if ano != _ano_anunciado:
		_ano_anunciado = ano
		year_changed.emit(ano)
