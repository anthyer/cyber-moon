extends Node

## Conduz a conversa com um NPC: escolhe a fala do dia, avança e encerra.
##
## Cada NPC tem uma Conversa (resources/dialogue/<id>.tres) com todas as falas dele. A
## fala do dia é uma só por NPC: falar de novo no mesmo dia repete, e no dia seguinte
## muda. Durante a conversa o relógio para, mas o jogo não pausa, para os personagens
## continuarem animados.
##
## Este autoload não desenha nada. A tela (CaixaDialogo) escuta os sinais.

signal dialogue_started(npc: Npc)
signal dialogue_ended(npc_id: String)
signal line_shown(no: NoDialogo)

const PASTA_DAS_CONVERSAS: String = "res://resources/dialogue/"
const ID_DO_JOGADOR: String = "jogador"
## Logo depois de abrir, o avançar é ignorado por este tempo. O mesmo aperto de botão que
## começou a conversa ainda está "recém-apertado" e pularia a primeira fala.
const SEGUNDOS_DE_TRAVA_AO_ABRIR: float = 0.2
## E logo depois de fechar, o mesmo vale ao contrário: o aperto que encerrou a conversa
## (F ou Esc) não pode reabri-la nem abrir o menu de pausa.
const SEGUNDOS_DE_TRAVA_AO_FECHAR: float = 0.2
## Uma fala dita fica este tanto de dias sem voltar, quando há outra que sirva. É a semana
## do jogo.
const DIAS_SEM_REPETIR: int = 6
## Abaixo desta fração da vida máxima, o jogador está "com a vida baixa" para as falas.
const FRACAO_DE_VIDA_BAIXA: float = 0.34

var em_dialogo: bool = false
## O NPC com quem o jogador está falando. Null fora de diálogo.
var interlocutor: Npc
## Verdadeiro quando o diálogo aberto é a conversa do dia, e falso quando é uma fala de
## evento (a reação a um presente). Só a conversa do dia conta ponto de amizade.
var e_conversa_do_dia: bool = false

var _conversa: Conversa
var _no_atual: NoDialogo
var _relogio_estava_congelado: bool = false
var _aberto_em_ms: int = 0
## Ids dos NPCs com quem o jogador já conversou hoje. Esvazia na virada do dia.
var _conversou_hoje: Dictionary[String, bool] = {}
## A fala que foi escolhida para cada NPC e em que dia, para ela não mudar no meio do dia
## se a situação mudar (começar a chover, o NPC trocar de lugar).
var _fala_escolhida: Dictionary[String, String] = {}
var _dia_da_fala_escolhida: Dictionary[String, int] = {}
## Id da fala para o último dia em que foi dita. É a memória que evita repetição e que
## garante a fala de uma vez só.
var _dia_em_que_foi_dita: Dictionary[String, int] = {}

func _ready() -> void:
	DayCycleManager.day_started.connect(func(_dia: int) -> void: _conversou_hoje.clear())

## Verdadeiro quando a conversa de hoje com este NPC já aconteceu: falar de novo só
## repete o que ele já disse. O indicador em cima do NPC usa isto para mudar de cor.
func ja_conversou_hoje(npc_id: String) -> bool:
	return _conversou_hoje.has(npc_id)
var _encerrado_em_ms: int = -100000

## Começa a conversa do dia com o NPC. Sem falas que sirvam, não acontece nada.
func iniciar(npc: Npc) -> void:
	if em_dialogo or acabou_de_encerrar() or npc == null or npc.perfil == null or StatusManager.esta_desmaiado:
		return
	var conversa: Conversa = conversa_de(npc.perfil.id)
	var fala: NoDialogo = fala_do_dia(npc.perfil.id)
	if conversa == null or fala == null:
		return
	_conversou_hoje[npc.perfil.id] = true
	_dia_em_que_foi_dita[fala.id] = DayCycleManager.numero_do_dia
	_abrir(npc, conversa, fala, true)

## Mostra uma fala de evento do NPC (a reação a um presente, a resposta ao buquê), fora do
## sorteio do dia. Sem a fala escrita na Conversa dele, não acontece nada.
func mostrar_fala_de_evento(npc: Npc, evento: StringName, animacao: StringName = &"idle") -> void:
	if em_dialogo or npc == null or npc.perfil == null:
		return
	var conversa: Conversa = conversa_de(npc.perfil.id)
	var texto: String = conversa.fala_de_evento(evento) if conversa != null else ""
	if texto == "":
		return
	var fala: NoDialogo = NoDialogo.new()
	fala.falante_id = npc.perfil.id
	fala.texto = texto
	fala.animacao = animacao
	_abrir(npc, conversa, fala, false)

func _abrir(npc: Npc, conversa: Conversa, fala: NoDialogo, do_dia: bool) -> void:
	em_dialogo = true
	interlocutor = npc
	e_conversa_do_dia = do_dia
	_conversa = conversa
	_aberto_em_ms = Time.get_ticks_msec()
	# Guarda como o relógio estava, para não soltá-lo ao fim se outro sistema (a dungeon,
	# o menu de debug) já o tinha parado.
	_relogio_estava_congelado = DayCycleManager.tempo_congelado
	DayCycleManager.tempo_congelado = true
	dialogue_started.emit(npc)
	_mostrar(fala)

## Passa para a próxima fala, ou encerra quando a atual não tem continuação.
func avancar() -> void:
	if not em_dialogo or Time.get_ticks_msec() - _aberto_em_ms < int(SEGUNDOS_DE_TRAVA_AO_ABRIR * 1000.0):
		return
	var proximo: NoDialogo = null
	if not _no_atual.proximos_nos.is_empty():
		proximo = _conversa.no_por_id(_no_atual.proximos_nos[0])
	if proximo == null:
		encerrar()
	else:
		_mostrar(proximo)

func encerrar() -> void:
	if not em_dialogo:
		return
	var npc_id: String = interlocutor.perfil.id if is_instance_valid(interlocutor) else ""
	em_dialogo = false
	interlocutor = null
	_conversa = null
	_no_atual = null
	_encerrado_em_ms = Time.get_ticks_msec()
	DayCycleManager.tempo_congelado = _relogio_estava_congelado
	dialogue_ended.emit(npc_id)

## Verdadeiro por um instante depois de a conversa fechar. Quem reage ao mesmo botão que
## a fecha (o menu de pausa com o Esc, a interação com o F) consulta isto para não agir.
func acabou_de_encerrar() -> bool:
	return Time.get_ticks_msec() - _encerrado_em_ms < int(SEGUNDOS_DE_TRAVA_AO_FECHAR * 1000.0)

func conversa_de(npc_id: String) -> Conversa:
	var caminho: String = PASTA_DAS_CONVERSAS + npc_id + ".tres"
	if not ResourceLoader.exists(caminho):
		return null
	return load(caminho) as Conversa

## A fala que abre a conversa de hoje com este NPC.
##
## Entre as falas que servem para o momento (amizade, estação, clima, dia, lugar, datas e
## situações), vence a mais específica. Para a mesma fala específica não se repetir todo
## dia, a que foi dita há pouco fica de fora, e a escolha desce para as menos específicas.
## Dentro do grupo, o número do dia escolhe, no lugar de um sorteio. A fala escolhida vale
## o dia inteiro: falar de novo no mesmo dia repete a mesma.
func fala_do_dia(npc_id: String) -> NoDialogo:
	var conversa: Conversa = conversa_de(npc_id)
	if conversa == null:
		return null
	var hoje: int = DayCycleManager.numero_do_dia
	if _dia_da_fala_escolhida.get(npc_id, -1) == hoje:
		var ja_escolhida: NoDialogo = conversa.no_por_id(_fala_escolhida.get(npc_id, ""))
		if ja_escolhida != null:
			return ja_escolhida
	var candidatos: Array[NoDialogo] = conversa.candidatos(relacionamento_com(npc_id), SeasonManager.estacao_atual(), situacoes_atuais(npc_id), RelationshipManager.esta_namorando(npc_id))
	var escolhida: NoDialogo = _escolher(candidatos, npc_id)
	if escolhida != null:
		_dia_da_fala_escolhida[npc_id] = hoje
		_fala_escolhida[npc_id] = escolhida.id
	return escolhida

func _escolher(candidatos: Array[NoDialogo], npc_id: String) -> NoDialogo:
	if candidatos.is_empty():
		return null
	var hoje: int = DayCycleManager.numero_do_dia
	# As frescas são as que podem ser ditas sem cansar: a de uma vez só que nunca foi
	# dita, e as outras que não foram ditas nos últimos dias.
	var frescas: Array[NoDialogo] = []
	for no in candidatos:
		var dita_no_dia: int = _dia_em_que_foi_dita.get(no.id, -1)
		if dita_no_dia == -1 or (not no.uma_vez and hoje - dita_no_dia >= DIAS_SEM_REPETIR):
			frescas.append(no)
	# Sem nenhuma fresca, vale repetir uma comum; a de uma vez só continua de fora.
	if frescas.is_empty():
		for no in candidatos:
			if not no.uma_vez:
				frescas.append(no)
	if frescas.is_empty():
		return null
	var maior: int = 0
	for no in frescas:
		maior = maxi(maior, no.especificidade())
	var mais_especificas: Array[NoDialogo] = []
	for no in frescas:
		if no.especificidade() == maior:
			mais_especificas.append(no)
	return mais_especificas[(hoje + absi(npc_id.hash())) % mais_especificas.size()]

## As situações que valem agora para a conversa com este NPC, pelo nome. São as condições
## que as falas citam; a lista e o que cada uma quer dizer estão em
## equipe/personas/leiame.md. Este é o único lugar que pergunta aos outros sistemas.
func situacoes_atuais(npc_id: String) -> Dictionary:
	var ativas: Dictionary = {}
	# Clima de hoje e de ontem.
	ativas[WeatherManager.clima_atual] = true
	if WeatherManager.clima_de_ontem == &"tempestade":
		ativas[&"tempestade_ontem"] = true
	if WeatherManager.clima_de_ontem in [&"chuva", &"tempestade"]:
		ativas[&"choveu_ontem"] = true
	# Dia da semana.
	var dia_da_semana: int = SeasonManager.dia_da_semana()
	if dia_da_semana == SeasonManager.DIA_DE_FOLGA:
		ativas[&"folga"] = true
	else:
		ativas[&"trabalho"] = true
	if dia_da_semana == SeasonManager.DIA_DE_FOLGA - 1:
		ativas[&"vespera_de_folga"] = true
	# Hora do dia.
	if DayCycleManager.hora_atual < DayCycleManager.HORA_MEIO_DIA:
		ativas[&"manha"] = true
	elif DayCycleManager.hora_atual < DayCycleManager.HORA_ANOITECER:
		ativas[&"tarde"] = true
	else:
		ativas[&"noite"] = true
	# Datas do calendário.
	var dia_da_estacao: int = SeasonManager.dia_da_estacao()
	if dia_da_estacao == 1:
		ativas[&"primeiro_dia_da_estacao"] = true
		if SeasonManager.indice_da_estacao() == 0:
			ativas[&"primeiro_dia_do_ano"] = true
	if dia_da_estacao == SeasonManager.DIAS_POR_ESTACAO:
		ativas[&"ultimo_dia_da_estacao"] = true
	for perfil in ElencoDeNpcs.carregar_perfis():
		if not perfil.faz_aniversario(SeasonManager.estacao_atual(), dia_da_estacao):
			continue
		if perfil.id == npc_id:
			ativas[&"aniversario"] = true
		else:
			ativas[StringName("aniversario_de:" + perfil.id)] = true
	# O jogador e a relação com este NPC.
	if not RelationshipManager.ja_conversou_com(npc_id):
		ativas[&"primeiro_encontro"] = true
	elif RelationshipManager.dias_sem_conversar_com(npc_id) >= RelationshipManager.DIAS_ATE_DECAIR:
		ativas[&"sumido"] = true
	if RelationshipManager.namorando != "" and RelationshipManager.namorando != npc_id:
		ativas[&"namorando_outro"] = true
	if StatusManager.desmaiou_ontem:
		ativas[&"desmaiou_ontem"] = true
	if StatusManager.vida_atual < StatusManager.vida_maxima() * FRACAO_DE_VIDA_BAIXA:
		ativas[&"vida_baixa"] = true
	if DungeonManager.dia_da_ultima_visita == DayCycleManager.numero_do_dia and not DungeonManager.esta_na_dungeon():
		ativas[&"saiu_da_dungeon"] = true
	for marco: String in GameManager.marcos_desbloqueados:
		ativas[StringName(marco)] = true
	# Onde este NPC está agora.
	var npc: Npc = _npc_de(npc_id)
	if npc != null and npc.lugar_atual() != &"":
		ativas[StringName("em:" + String(npc.lugar_atual()))] = true
	return ativas

func _npc_de(npc_id: String) -> Npc:
	for no in get_tree().get_nodes_in_group(Npc.GRUPO):
		var npc: Npc = no as Npc
		if npc != null and npc.perfil != null and npc.perfil.id == npc_id:
			return npc
	return null

## Os pontos de relacionamento com o NPC, que decidem a faixa de falas dele.
func relacionamento_com(npc_id: String) -> int:
	return RelationshipManager.pontos_de(npc_id)

func _mostrar(no: NoDialogo) -> void:
	_no_atual = no
	line_shown.emit(no)

# Save

## Só quem já conversou hoje. Sem isso, carregar o jogo no meio do dia deixaria o balão
## amarelo de volta em cima de quem já falou.
func exportar_estado() -> Dictionary:
	return {
		"conversou_hoje": _conversou_hoje.keys(),
		"fala_escolhida": _fala_escolhida,
		"dia_da_fala_escolhida": _dia_da_fala_escolhida,
		"dia_em_que_foi_dita": _dia_em_que_foi_dita,
	}

func importar_estado(dados: Dictionary) -> void:
	_conversou_hoje.clear()
	_fala_escolhida.clear()
	_dia_da_fala_escolhida.clear()
	_dia_em_que_foi_dita.clear()
	for npc_id: String in dados.get("conversou_hoje", []):
		_conversou_hoje[npc_id] = true
	for npc_id: String in dados.get("fala_escolhida", {}):
		_fala_escolhida[npc_id] = String(dados["fala_escolhida"][npc_id])
	for npc_id: String in dados.get("dia_da_fala_escolhida", {}):
		_dia_da_fala_escolhida[npc_id] = int(dados["dia_da_fala_escolhida"][npc_id])
	for id_da_fala: String in dados.get("dia_em_que_foi_dita", {}):
		_dia_em_que_foi_dita[id_da_fala] = int(dados["dia_em_que_foi_dita"][id_da_fala])
