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

## A fala que abre a conversa de hoje com este NPC. O número do dia entra na conta no
## lugar de um sorteio: assim a fala é a mesma o dia inteiro e muda no dia seguinte.
## Somar o hash do id evita que todos os NPCs troquem de fala em sincronia.
func fala_do_dia(npc_id: String) -> NoDialogo:
	var conversa: Conversa = conversa_de(npc_id)
	if conversa == null:
		return null
	var candidatos: Array[NoDialogo] = conversa.candidatos(relacionamento_com(npc_id), SeasonManager.estacao_atual())
	if candidatos.is_empty():
		return null
	var indice: int = (DayCycleManager.numero_do_dia + absi(npc_id.hash())) % candidatos.size()
	return candidatos[indice]

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
	return {"conversou_hoje": _conversou_hoje.keys()}

func importar_estado(dados: Dictionary) -> void:
	_conversou_hoje.clear()
	for npc_id: String in dados.get("conversou_hoje", []):
		_conversou_hoje[npc_id] = true
