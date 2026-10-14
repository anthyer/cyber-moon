class_name SalaDeDungeon
extends Node3D

## Uma sala da dungeon: os inimigos que nascem nela e as portas que ela abre.
##
## Os inimigos da sala ficam adormecidos até a sala ser ativada, para não sentirem o
## jogador através da parede. A primeira sala começa ativa; as outras acordam quando a
## anterior fica limpa. Limpar a sala (derrubar o último inimigo dela) abre as portas e
## acorda as salas seguintes.
##
## Nada aqui passa pela rede. A queda de cada inimigo já é igual em todos os jogos (a
## Dungeon cuida disso, e o fantoche do convidado também avisa quando cai), então a sala
## fica limpa e a porta abre em cada jogo por conta própria, no mesmo momento.

signal cleared(sala: SalaDeDungeon)

## A primeira sala da dungeon: os inimigos dela já nascem acordados.
@export var comeca_ativa: bool = false
## As PortaDeDungeon que abrem quando a sala fica limpa.
@export var portas: Array[NodePath] = []
## As salas que acordam quando esta fica limpa.
@export var proximas_salas: Array[NodePath] = []
@export var nome_exibido: String = ""

var _inimigos: Array[Inimigo] = []
var _ativa: bool = false
var _limpa: bool = false

func _ready() -> void:
	var dungeon: Dungeon = _dungeon()
	if dungeon != null:
		dungeon.enemy_defeated.connect(_ao_cair_inimigo)
	if comeca_ativa:
		# Um quadro depois, porque a Dungeon entrega os inimigos no _ready dela, que roda
		# depois do das salas. Ativar antes veria a sala vazia e a daria por limpa.
		ativar.call_deferred()

## Chamado pela Dungeon para cada inimigo cujo ponto está dentro desta sala.
func adotar_inimigo(inimigo: Inimigo) -> void:
	_inimigos.append(inimigo)
	inimigo.adormecido = not _ativa

## Acorda os inimigos. Uma sala sem inimigos fica limpa na hora, e passa adiante.
func ativar() -> void:
	if _ativa:
		return
	_ativa = true
	for inimigo in _inimigos:
		if is_instance_valid(inimigo):
			inimigo.adormecido = false
	_conferir_se_esta_limpa()

func esta_ativa() -> bool:
	return _ativa

func esta_limpa() -> bool:
	return _limpa

func inimigos_vivos() -> int:
	var vivos: int = 0
	for inimigo in _inimigos:
		if is_instance_valid(inimigo) and inimigo.esta_vivo():
			vivos += 1
	return vivos

func _ao_cair_inimigo(inimigo: Inimigo) -> void:
	if not _inimigos.has(inimigo):
		return
	_inimigos.erase(inimigo)
	# O brilho de sala limpa sai de onde caiu o último inimigo.
	_conferir_se_esta_limpa(inimigo.global_position)

func _conferir_se_esta_limpa(posicao_do_aviso: Vector3 = Vector3.INF) -> void:
	if _limpa or not _ativa or not _inimigos.is_empty():
		return
	_limpa = true
	cleared.emit(self)
	if posicao_do_aviso != Vector3.INF:
		EventBus.dungeon_room_cleared.emit(posicao_do_aviso)
	for caminho in portas:
		var porta: PortaDeDungeon = get_node_or_null(caminho) as PortaDeDungeon
		if porta != null:
			porta.abrir()
	for caminho in proximas_salas:
		var sala: SalaDeDungeon = get_node_or_null(caminho) as SalaDeDungeon
		if sala != null:
			sala.ativar()

## A Dungeon é um ancestral da sala. Sobe pela árvore até achar.
func _dungeon() -> Dungeon:
	var pai: Node = get_parent()
	while pai != null:
		if pai is Dungeon:
			return pai as Dungeon
		pai = pai.get_parent()
	return null
