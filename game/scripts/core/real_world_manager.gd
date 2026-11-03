extends Node

## Liga o jogo ao mundo de fora (plano 37): a hora inicial vem do relógio do computador,
## o clima do dia vem do tempo real de Florianópolis (Open-Meteo) e a fase da Lua vem do
## calendário real (USNO).
##
## Este autoload só pergunta ao mundo de fora e avisa o resto do jogo. Ele não mexe em
## planta, luz nem interface: o WeatherManager escuta real_weather_received, e a
## GradeSolo, a IluminacaoDoCiclo e o relógio da tela leem fase_da_lua e escutam
## moon_phase_changed.
##
## O tempo real não substitui o relógio do jogo. A hora é sincronizada uma vez, ao abrir;
## depois disso o DayCycleManager anda na velocidade de sempre, e o dia só vira dormindo.
## A estação e o número do dia continuam sendo do jogo.
##
## Estar sem internet não é erro. Qualquer resposta que não chegue a tempo, ou que venha
## fora do formato esperado, cai na reserva (o clima sorteado, a Lua calculada) com um
## push_warning. O jogo nunca espera a rede para começar.
##
## Não salva nada: hora, clima e Lua são consultados de novo a cada abertura.

signal real_weather_received(clima: StringName)
signal moon_phase_changed(fase: FaseDaLua)

enum FaseDaLua { NOVA, CRESCENTE, CHEIA, MINGUANTE }

const CAMINHO_DA_CONFIGURACAO: String = "res://resources/mundo_real/configuracao.tres"
## Para testar a hora inicial sem esperar o relógio: godot --path game -- --hora-real=03:00
const ARGUMENTO_DA_HORA_REAL: String = "--hora-real="

## Os nomes das fases principais na resposta do USNO. É o formato da API, não dado de jogo.
const FASE_POR_NOME_NO_USNO: Dictionary[String, FaseDaLua] = {
	"New Moon": FaseDaLua.NOVA,
	"First Quarter": FaseDaLua.CRESCENTE,
	"Full Moon": FaseDaLua.CHEIA,
	"Last Quarter": FaseDaLua.MINGUANTE,
}
const NOMES_DAS_FASES: Array[String] = ["Lua nova", "Lua crescente", "Lua cheia", "Lua minguante"]

## Para a conta local: houve lua nova em 6 de janeiro de 2000, às 18:14 UTC, e o mês
## lunar tem 29,53 dias. A conta erra por cerca de um dia, o que não importa para o jogo.
const UNIX_DA_LUA_NOVA_DE_REFERENCIA: float = 947182440.0
const DIAS_DO_MES_LUNAR: float = 29.530588853
const SEGUNDOS_POR_DIA: float = 86400.0

var fase_da_lua: FaseDaLua = FaseDaLua.NOVA
## Falso quando a fase veio da conta local, para o menu de debug mostrar a origem.
var fase_veio_da_api: bool = false
## Falso enquanto o clima do dia for o sorteado (ou o do save).
var clima_veio_da_api: bool = false
## A hora real lida ao abrir, antes de ser encaixada no dia do jogo. Para o menu de debug.
var hora_real_lida: String = ""

var _configuracao: ConfiguracaoMundoReal
var _pedido_do_clima: HTTPRequest
var _pedido_da_lua: HTTPRequest
## A data real (AAAA-MM-DD) da última vez que a fase foi definida. A Lua segue o
## calendário real: dormir três vezes no mesmo dia real não troca a fase.
var _data_da_fase: String = ""
## Para o primeiro _definir_fase anunciar mesmo quando a fase é a padrão (nova).
var _fase_ja_anunciada: bool = false

func _ready() -> void:
	_configuracao = load(CAMINHO_DA_CONFIGURACAO) as ConfiguracaoMundoReal
	_pedido_do_clima = _criar_pedido(_ao_responder_o_clima)
	_pedido_da_lua = _criar_pedido(_ao_responder_a_lua)
	# A fase da conta local vale desde o primeiro quadro; a da API, se vier, troca depois.
	_definir_fase(fase_calculada_localmente(Time.get_unix_time_from_system()), false)
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)
	# A hora e o clima esperam o save carregar, senão o save sobrescreve o que veio de fora.
	if SaveManager.ativo and SaveManager.existe_save():
		SaveManager.game_loaded.connect(_ao_abrir_o_jogo, CONNECT_ONE_SHOT)
	else:
		_ao_abrir_o_jogo.call_deferred()

func _ao_abrir_o_jogo() -> void:
	sincronizar_hora_inicial()
	consultar_clima()
	consultar_fase_da_lua()

## O clima continua sem mudar no meio do dia (plano 13): a consulta só troca o clima do
## dia que acabou de começar.
func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	clima_veio_da_api = false
	consultar_clima()
	if _data_de_hoje() != _data_da_fase:
		consultar_fase_da_lua()

# Hora

## Põe o relógio do jogo na hora real, uma vez. O dia do jogo vai das 6:00 à 1:00, então
## a madrugada real (da 0:00 às 5:59) começa às 6:00: abrir à 0:30 e cair de sono poucos
## segundos depois seria frustrante.
func sincronizar_hora_inicial() -> void:
	var hora_e_minuto: Vector2i = _hora_real()
	hora_real_lida = "%02d:%02d" % [hora_e_minuto.x, hora_e_minuto.y]
	var hora: float = hora_e_minuto.x + hora_e_minuto.y / 60.0
	if hora < DayCycleManager.HORA_INICIO_DIA:
		hora = DayCycleManager.HORA_INICIO_DIA
	DayCycleManager.definir_hora(hora)

## A hora do argumento --hora-real=HH:MM, se houver, ou a do sistema.
func _hora_real() -> Vector2i:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with(ARGUMENTO_DA_HORA_REAL):
			var partes: PackedStringArray = argumento.trim_prefix(ARGUMENTO_DA_HORA_REAL).split(":")
			if partes.size() == 2 and partes[0].is_valid_int() and partes[1].is_valid_int():
				return Vector2i(clampi(partes[0].to_int(), 0, 23), clampi(partes[1].to_int(), 0, 59))
			push_warning("Argumento %s fora do formato HH:MM; usando a hora do sistema." % argumento)
	var agora: Dictionary = Time.get_time_dict_from_system()
	return Vector2i(int(agora.hour), int(agora.minute))

# Clima

func consultar_clima() -> void:
	if not _configuracao.usar_apis:
		return
	_pedido_do_clima.cancel_request()
	var erro: Error = _pedido_do_clima.request(_configuracao.url_do_clima_pronta())
	if erro != OK:
		push_warning("Clima real: não foi possível fazer a consulta (%s). Fica o clima sorteado." % error_string(erro))

func _ao_responder_o_clima(resultado: int, codigo_http: int, _cabecalhos: PackedStringArray, corpo: PackedByteArray) -> void:
	var dados: Dictionary = _ler_json(resultado, codigo_http, corpo, "Clima real")
	var atual: Variant = dados.get("current")
	if not atual is Dictionary or not (atual as Dictionary).get("weather_code") is float:
		if not dados.is_empty():
			push_warning("Clima real: resposta sem current.weather_code. Fica o clima sorteado.")
		return
	var clima: StringName = clima_do_codigo_wmo(int((atual as Dictionary)["weather_code"]))
	if clima == &"":
		push_warning("Clima real: código WMO %d sem clima na configuração. Fica o clima sorteado." % int(atual["weather_code"]))
		return
	clima_veio_da_api = true
	real_weather_received.emit(clima)

## O clima do jogo para um código WMO, pela tabela da configuração. Vazio se o código não
## está na tabela.
func clima_do_codigo_wmo(codigo: int) -> StringName:
	return _configuracao.clima_por_codigo_wmo.get(codigo, &"")

# Lua

func consultar_fase_da_lua() -> void:
	var hoje_em_unix: float = Time.get_unix_time_from_system()
	# A conta local primeiro: é a reserva se a API não responder, e já vale enquanto espera.
	_definir_fase(fase_calculada_localmente(hoje_em_unix), false)
	if not _configuracao.usar_apis:
		return
	var inicio: float = hoje_em_unix - _configuracao.dias_antes_de_hoje_na_consulta_da_lua * SEGUNDOS_POR_DIA
	_pedido_da_lua.cancel_request()
	var erro: Error = _pedido_da_lua.request(_configuracao.url_da_lua_pronta(Time.get_date_string_from_unix_time(int(inicio))))
	if erro != OK:
		push_warning("Fase da Lua: não foi possível fazer a consulta (%s). Fica a conta local." % error_string(erro))

## A resposta traz as fases principais a partir de alguns dias atrás. A fase de hoje é a
## última da lista com data até hoje.
func _ao_responder_a_lua(resultado: int, codigo_http: int, _cabecalhos: PackedStringArray, corpo: PackedByteArray) -> void:
	var dados: Dictionary = _ler_json(resultado, codigo_http, corpo, "Fase da Lua")
	if dados.is_empty():
		return
	var lista: Variant = dados.get("phasedata")
	if not lista is Array:
		push_warning("Fase da Lua: resposta sem phasedata. Fica a conta local.")
		return
	var hoje: String = _data_de_hoje()
	var fase_de_hoje: int = -1
	for entrada: Variant in lista:
		if not entrada is Dictionary:
			continue
		var data: String = "%04d-%02d-%02d" % [int(entrada.get("year", 0)), int(entrada.get("month", 0)), int(entrada.get("day", 0))]
		var nome: String = str(entrada.get("phase", ""))
		if data <= hoje and FASE_POR_NOME_NO_USNO.has(nome):
			fase_de_hoje = FASE_POR_NOME_NO_USNO[nome]
	if fase_de_hoje < 0:
		push_warning("Fase da Lua: nenhuma fase até hoje na resposta. Fica a conta local.")
		return
	_definir_fase(fase_de_hoje as FaseDaLua, true)

## A fase principal mais recente numa data, pela conta do mês lunar médio. O ciclo é
## dividido em quatro quartos iguais, cada um começando numa fase principal, igual à regra
## da API (a última fase até hoje).
func fase_calculada_localmente(data_unix: float) -> FaseDaLua:
	var dias: float = (data_unix - UNIX_DA_LUA_NOVA_DE_REFERENCIA) / SEGUNDOS_POR_DIA
	var idade_da_lua: float = fposmod(dias, DIAS_DO_MES_LUNAR)
	var quarto: int = int(idade_da_lua / (DIAS_DO_MES_LUNAR / 4.0))
	return clampi(quarto, 0, 3) as FaseDaLua

## Troca a fase na hora. Serve ao menu de debug, para testar a luz e os bônus de cada fase.
func forcar_fase(fase: FaseDaLua) -> void:
	_definir_fase(fase, false)

func nome_da_fase(fase: FaseDaLua = fase_da_lua) -> String:
	return NOMES_DAS_FASES[fase]

func configuracao() -> ConfiguracaoMundoReal:
	return _configuracao

func _definir_fase(fase: FaseDaLua, veio_da_api: bool) -> void:
	_data_da_fase = _data_de_hoje()
	fase_veio_da_api = veio_da_api
	if fase == fase_da_lua and _fase_ja_anunciada:
		return
	_fase_ja_anunciada = true
	fase_da_lua = fase
	moon_phase_changed.emit(fase)

# Comum

func _criar_pedido(ao_responder: Callable) -> HTTPRequest:
	var pedido: HTTPRequest = HTTPRequest.new()
	pedido.timeout = _configuracao.segundos_de_limite
	# A consulta continua andando com o menu de pausa aberto.
	pedido.process_mode = Node.PROCESS_MODE_ALWAYS
	pedido.request_completed.connect(ao_responder)
	add_child(pedido)
	return pedido

## O corpo da resposta como dicionário, ou vazio (com aviso) quando não houve resposta
## útil: sem rede, tempo esgotado, código HTTP de erro ou JSON quebrado.
func _ler_json(resultado: int, codigo_http: int, corpo: PackedByteArray, assunto: String) -> Dictionary:
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo_http != 200:
		push_warning("%s: sem resposta (resultado %d, HTTP %d). Fica a reserva." % [assunto, resultado, codigo_http])
		return {}
	var lido: Variant = JSON.parse_string(corpo.get_string_from_utf8())
	if not lido is Dictionary:
		push_warning("%s: resposta fora do formato. Fica a reserva." % assunto)
		return {}
	return lido

## A data local de hoje, AAAA-MM-DD. A Lua muda quando o dia real muda.
func _data_de_hoje() -> String:
	return Time.get_date_string_from_system()
