extends Node

## A amizade com cada NPC: os pontos, os corações, o presente da semana, o decaimento de
## quem some e o namoro.
##
## O ponto é a unidade interna e o coração é o que o jogador vê: 250 pontos por coração,
## dez corações no máximo. Conversar uma vez por dia e dar um presente por semana sobem a
## amizade; ficar mais de uma semana sem conversar faz ela cair devagar, mas nunca abaixo
## do coração já conquistado.
##
## Os números estão em equipe/planos/16-amizade-e-romance.md, seção Balanceamento.

signal relationship_changed(npc_id: String, pontos: int, coracoes: int)
signal heart_gained(npc_id: String, coracoes: int)
signal dating_started(npc_id: String)

enum ResultadoPresente { AMOU, GOSTOU, NEUTRO, NAO_GOSTOU, ODIOU, JA_PRESENTEOU_ESTA_SEMANA }
enum ResultadoBuque { ACEITO, POUCOS_CORACOES, NAO_ROMANCEAVEL, JA_NAMORANDO }

const PONTOS_POR_CORACAO: int = 250
const CORACOES_MAXIMOS: int = 10
const PONTOS_MAXIMOS: int = PONTOS_POR_CORACAO * CORACOES_MAXIMOS
const PONTOS_POR_CONVERSA: int = 20
const PONTOS_POR_PRESENTE: Dictionary = {
	ResultadoPresente.AMOU: 80,
	ResultadoPresente.GOSTOU: 45,
	ResultadoPresente.NEUTRO: 20,
	ResultadoPresente.NAO_GOSTOU: -20,
	ResultadoPresente.ODIOU: -40,
}
const MULTIPLICADOR_DE_ANIVERSARIO: int = 3
const DIAS_ATE_DECAIR: int = 7
const PONTOS_DE_DECAIMENTO: int = 10

## npc_id para pontos. Quem não está aqui ainda tem o relacionamento inicial do perfil.
var pontos: Dictionary[String, int] = {}
## npc_id para o número do dia da última conversa. Quem não está aqui conta do dia 1.
var dia_da_ultima_conversa: Dictionary[String, int] = {}
## npc_id para o número da semana em que ganhou o último presente.
var semana_do_ultimo_presente: Dictionary[String, int] = {}
## Id do NPC com quem o jogador namora. Vazio quando não namora ninguém.
var namorando: String = ""

var _perfis: Dictionary[String, PerfilNpc] = {}

func _ready() -> void:
	for perfil in ElencoDeNpcs.carregar_perfis():
		_perfis[perfil.id] = perfil
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)
	DialogueManager.dialogue_started.connect(_ao_comecar_dialogo)

func perfil_de(npc_id: String) -> PerfilNpc:
	return _perfis.get(npc_id, null)

func pontos_de(npc_id: String) -> int:
	if pontos.has(npc_id):
		return pontos[npc_id]
	var perfil: PerfilNpc = perfil_de(npc_id)
	return perfil.relacionamento_inicial if perfil != null else 0

## 0 a 10.
func coracoes(npc_id: String) -> int:
	return mini(int(pontos_de(npc_id) / PONTOS_POR_CORACAO), CORACOES_MAXIMOS)

func esta_namorando(npc_id: String) -> bool:
	return namorando != "" and namorando == npc_id

## Soma (ou tira) pontos, sem sair de 0 a PONTOS_MAXIMOS, e avisa o que mudou.
func somar_pontos(npc_id: String, quantidade: int) -> void:
	var coracoes_antes: int = coracoes(npc_id)
	pontos[npc_id] = clampi(pontos_de(npc_id) + quantidade, 0, PONTOS_MAXIMOS)
	var coracoes_agora: int = coracoes(npc_id)
	relationship_changed.emit(npc_id, pontos[npc_id], coracoes_agora)
	if coracoes_agora > coracoes_antes:
		heart_gained.emit(npc_id, coracoes_agora)
		EventBus.notice_requested.emit("%s: %d de %d corações." % [_nome_de(npc_id), coracoes_agora, CORACOES_MAXIMOS])

## A conversa do dia. Dá ponto só na primeira vez no dia; devolve false nas outras.
func registrar_conversa(npc_id: String) -> bool:
	var hoje: int = DayCycleManager.numero_do_dia
	if dia_da_ultima_conversa.get(npc_id, 0) == hoje:
		return false
	dia_da_ultima_conversa[npc_id] = hoje
	somar_pontos(npc_id, PONTOS_POR_CONVERSA)
	return true

## Um presente por semana do jogo (6 dias). O contador zera na virada da semana, e não
## 6 dias depois do último presente, que é mais fácil de entender.
func pode_presentear(npc_id: String) -> bool:
	return semana_do_ultimo_presente.get(npc_id, -1) != _semana_atual()

## Como o NPC recebe o item, pelas listas de gosto do perfil. Item fora das listas é
## neutro. Não mexe em pontos: serve para saber a reação antes de dar.
func reacao_ao_item(npc_id: String, item: Item) -> ResultadoPresente:
	var perfil: PerfilNpc = perfil_de(npc_id)
	if perfil == null or item == null:
		return ResultadoPresente.NEUTRO
	if perfil.itens_amados.has(item):
		return ResultadoPresente.AMOU
	if perfil.itens_queridos.has(item):
		return ResultadoPresente.GOSTOU
	if perfil.itens_indesejados.has(item):
		return ResultadoPresente.NAO_GOSTOU
	if perfil.itens_odiados.has(item):
		return ResultadoPresente.ODIOU
	return ResultadoPresente.NEUTRO

## Dá o presente: soma os pontos da reação e marca a semana. No aniversário, o presente
## de que ele gosta vale o triplo; o de que não gosta não é triplicado, para o
## aniversário nunca ser uma armadilha.
func presentear(npc_id: String, item: Item) -> ResultadoPresente:
	if not pode_presentear(npc_id):
		return ResultadoPresente.JA_PRESENTEOU_ESTA_SEMANA
	var resultado: ResultadoPresente = reacao_ao_item(npc_id, item)
	var ganho: int = PONTOS_POR_PRESENTE[resultado]
	if ganho > 0 and e_aniversario_de(npc_id):
		ganho *= MULTIPLICADOR_DE_ANIVERSARIO
	semana_do_ultimo_presente[npc_id] = _semana_atual()
	somar_pontos(npc_id, ganho)
	return resultado

func e_aniversario_de(npc_id: String) -> bool:
	var perfil: PerfilNpc = perfil_de(npc_id)
	return perfil != null and perfil.faz_aniversario(SeasonManager.estacao_atual(), SeasonManager.dia_da_estacao())

## O que aconteceria ao dar o buquê, sem dar. O buquê só é aceito por NPC romanceável,
## com dez corações, e com o jogador sem namorar ninguém.
func resposta_ao_buque(npc_id: String) -> ResultadoBuque:
	var perfil: PerfilNpc = perfil_de(npc_id)
	if perfil == null or not perfil.eh_romanceavel:
		return ResultadoBuque.NAO_ROMANCEAVEL
	if namorando != "":
		return ResultadoBuque.JA_NAMORANDO
	if coracoes(npc_id) < CORACOES_MAXIMOS:
		return ResultadoBuque.POUCOS_CORACOES
	return ResultadoBuque.ACEITO

func pedir_em_namoro(npc_id: String) -> ResultadoBuque:
	var resposta: ResultadoBuque = resposta_ao_buque(npc_id)
	if resposta == ResultadoBuque.ACEITO:
		namorando = npc_id
		dating_started.emit(npc_id)
	return resposta

## Só a conversa do dia conta ponto. A fala de reação a um presente também passa pelo
## DialogueManager, mas não é conversa.
func _ao_comecar_dialogo(npc: Npc) -> void:
	if DialogueManager.e_conversa_do_dia and npc != null and npc.perfil != null:
		registrar_conversa(npc.perfil.id)

## Quem passou DIAS_ATE_DECAIR dias sem conversa perde um pouco por dia, até o piso do
## coração em que está. Assim o jogador nunca perde um coração inteiro por descuido.
func _ao_comecar_o_dia(numero_do_dia: int) -> void:
	for npc_id: String in _perfis:
		var dias_sem_conversar: int = numero_do_dia - dia_da_ultima_conversa.get(npc_id, 1)
		if dias_sem_conversar < DIAS_ATE_DECAIR:
			continue
		var piso: int = coracoes(npc_id) * PONTOS_POR_CORACAO
		var novos: int = maxi(pontos_de(npc_id) - PONTOS_DE_DECAIMENTO, piso)
		if novos != pontos_de(npc_id):
			somar_pontos(npc_id, novos - pontos_de(npc_id))

func _semana_atual() -> int:
	return int((DayCycleManager.numero_do_dia - 1) / SeasonManager.DIAS_POR_SEMANA)

func _nome_de(npc_id: String) -> String:
	var perfil: PerfilNpc = perfil_de(npc_id)
	return perfil.nome_exibido if perfil != null else npc_id
