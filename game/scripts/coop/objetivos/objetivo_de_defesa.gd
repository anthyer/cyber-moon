class_name ObjetivoDeDefesa
extends ObjetivoParalelo

## Objetivo paralelo: proteger um ponto enquanto os inimigos de uma sala estão vivos.
##
## O ponto perde vida por segundo conforme quantos inimigos acordados estão perto dele.
## Nenhum inimigo o ataca de propósito: a pressa é do jogador, que precisa limpar a sala
## antes de a vida acabar. Sala limpa com o ponto de pé cumpre; vida zerada falha.
##
## Só o jogo anfitrião faz a conta, porque é ele quem manda nos inimigos. Os outros
## recebem a vida e o desfecho por aviso.

const EVENTO_DE_DEFESA: String = "objetivo_defesa"
const ENVIOS_POR_SEGUNDO: float = 4.0
## O desfecho que viaja no aviso, para os outros jogos fecharem o objetivo igual.
enum Desfecho { EM_ANDAMENTO, CONCLUIDO, FALHOU }

## A SalaDeDungeon cujos inimigos ameaçam o ponto.
@export var caminho_da_sala: NodePath
@export var vida_do_ponto: float = 100.0
## Quanto de vida o ponto perde por segundo para cada inimigo acordado dentro do raio.
@export var dano_por_inimigo_por_segundo: float = 2.0
@export var raio_de_ameaca: float = 8.0
## O nome do ponto, como aparece na tela: "Antena".
@export var nome_do_ponto: String = "Ponto"

var _vida: float = 0.0
var _sala: SalaDeDungeon
var _ponto: PontoDeDefesa
## A conta só anda depois que o primeiro inimigo da sala acorda.
var _comecou: bool = false
var _segundos_ate_enviar: float = 0.0
## A porcentagem anunciada por último, para a tela não ser avisada a cada quadro.
var _porcentagem_anunciada: int = -1

func _init() -> void:
	mensagem_de_conclusao = "A antena aguentou."
	mensagem_de_falha = "A antena caiu."

func _preparar() -> void:
	_vida = vida_do_ponto
	_sala = get_node_or_null(caminho_da_sala) as SalaDeDungeon
	for no in find_children("*", "Node3D", true, false):
		if no is PontoDeDefesa:
			_ponto = no as PontoDeDefesa
			break
	if _sala != null:
		_sala.cleared.connect(_ao_limpar_a_sala)

func texto_de_progresso() -> String:
	return "%s: %d%%" % [nome_do_ponto, _porcentagem()]

func _process(delta: float) -> void:
	if concluido or falhou or not _sou_anfitriao() or _sala == null:
		return
	if not _comecou:
		# A sala ativa é a que já acordou os inimigos dela.
		_comecou = _sala.esta_ativa() and _sala.inimigos_vivos() > 0
		if not _comecou:
			return
	if _sala.esta_limpa():
		_fechar(Desfecho.CONCLUIDO)
		return
	var perto: int = _inimigos_acordados_no_raio()
	if perto > 0:
		_definir_vida(_vida - dano_por_inimigo_por_segundo * perto * delta)
		if _vida <= 0.0:
			_fechar(Desfecho.FALHOU)
			return
	_segundos_ate_enviar -= delta
	if _segundos_ate_enviar <= 0.0:
		_segundos_ate_enviar = 1.0 / ENVIOS_POR_SEGUNDO
		_enviar(Desfecho.EM_ANDAMENTO)

func _ao_receber_evento(_de: String, tipo: String, campos: Dictionary) -> void:
	if tipo != EVENTO_DE_DEFESA:
		return
	_definir_vida(float(campos.get("vida", _vida)))
	match int(campos.get("desfecho", Desfecho.EM_ANDAMENTO)):
		Desfecho.CONCLUIDO:
			_concluir()
		Desfecho.FALHOU:
			_falhar()

## A sala ficou limpa. No anfitrião, o ponto de pé cumpre o objetivo na hora, sem esperar
## o próximo quadro. Nos outros jogos quem decide é o aviso do anfitrião.
func _ao_limpar_a_sala(_sala_limpa: SalaDeDungeon) -> void:
	if _sou_anfitriao() and _vida > 0.0:
		_fechar(Desfecho.CONCLUIDO)

func _fechar(desfecho: Desfecho) -> void:
	if concluido or falhou:
		return
	_enviar(desfecho)
	if desfecho == Desfecho.CONCLUIDO:
		_concluir()
	else:
		_falhar()

func _enviar(desfecho: Desfecho) -> void:
	_avisar_os_outros(EVENTO_DE_DEFESA, {"vida": snappedf(_vida, 0.1), "desfecho": desfecho})

func _definir_vida(nova: float) -> void:
	_vida = clampf(nova, 0.0, vida_do_ponto)
	if _ponto != null:
		_ponto.definir_vida(_vida / vida_do_ponto if vida_do_ponto > 0.0 else 0.0)
	if _porcentagem() != _porcentagem_anunciada:
		_porcentagem_anunciada = _porcentagem()
		_anunciar()

func _porcentagem() -> int:
	return ceili(_vida / vida_do_ponto * 100.0) if vida_do_ponto > 0.0 else 0

## Quantos inimigos vivos e acordados da dungeon estão dentro do raio do ponto.
func _inimigos_acordados_no_raio() -> int:
	if dungeon == null:
		return 0
	var centro: Vector3 = _ponto.global_position if _ponto != null else global_position
	var total: int = 0
	for no in dungeon.get_children():
		var inimigo: Inimigo = no as Inimigo
		if inimigo == null or not inimigo.esta_vivo() or inimigo.adormecido:
			continue
		if inimigo.global_position.distance_to(centro) <= raio_de_ameaca:
			total += 1
	return total
