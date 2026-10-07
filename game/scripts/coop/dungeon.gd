class_name Dungeon
extends Node3D

## Uma dungeon de combate, sozinho ou em equipe.
##
## Em equipe, o servidor só repassa mensagens, então um dos jogos precisa mandar nos
## inimigos: é o do anfitrião. Aqui os inimigos são de verdade no jogo do anfitrião e
## fantoches no do convidado. O anfitrião transmite a posição e a vida deles; o convidado
## avisa quando acerta um golpe, e o anfitrião aplica. Cada jogador cuida da própria vida,
## experiência e saque.
##
## As mensagens trocadas estão em equipe/planos/22-dungeon-em-coop.md.

## Não sobrou jogador nenhum na dungeon, nem local nem remoto.
signal emptied

const CENA_DO_INIMIGO: PackedScene = preload("res://scenes/combat/inimigo.tscn")
const CENA_DO_JOGADOR_REMOTO: PackedScene = preload("res://scenes/coop/jogador_remoto.tscn")
const ENVIOS_DO_JOGADOR_POR_SEGUNDO: float = 12.0
const ENVIOS_DOS_INIMIGOS_POR_SEGUNDO: float = 10.0
## Distância entre os pontos em que cada jogador nasce, lado a lado na entrada.
const ESPACO_ENTRE_JOGADORES: float = 1.2

## O jogador deste jogo, enquanto está aqui dentro. Null quando ele não está (o anfitrião
## que morreu segue simulando de longe).
var jogador_local: CharacterBody3D

@onready var _entrada: Marker3D = $Entrada
@onready var _pontos_de_inimigo: Node3D = $PontosDeInimigo

## Decidido uma vez, ao criar a dungeon. Sozinho, o jogo é o próprio anfitrião.
var _sou_anfitriao: bool = true
## Número do inimigo na rede (a ordem do ponto na cena) para o inimigo.
var _inimigos: Dictionary[int, Inimigo] = {}
## Id do jogador para o fantoche dele.
var _remotos: Dictionary[String, JogadorRemoto] = {}
var _segundos_ate_enviar_o_jogador: float = 0.0
var _segundos_ate_enviar_os_inimigos: float = 0.0

func _ready() -> void:
	_sou_anfitriao = LobbyManager.sou_anfitriao()
	LobbyManager.room_message.connect(_ao_receber)
	LobbyManager.room_changed.connect(_ao_mudar_a_equipe)
	_criar_inimigos()

func _process(delta: float) -> void:
	if not LobbyManager.esta_em_sala():
		return
	_segundos_ate_enviar_o_jogador -= delta
	if _segundos_ate_enviar_o_jogador <= 0.0 and jogador_local != null:
		_segundos_ate_enviar_o_jogador = 1.0 / ENVIOS_DO_JOGADOR_POR_SEGUNDO
		_enviar_o_jogador()
	_segundos_ate_enviar_os_inimigos -= delta
	if _segundos_ate_enviar_os_inimigos <= 0.0 and _sou_anfitriao:
		_segundos_ate_enviar_os_inimigos = 1.0 / ENVIOS_DOS_INIMIGOS_POR_SEGUNDO
		_enviar_os_inimigos()

## Onde nasce o jogador de ordem dada na equipe (0 é o anfitrião), lado a lado.
func ponto_de_entrada(ordem: int) -> Vector3:
	return _entrada.global_position + Vector3((float(ordem) - 0.5) * ESPACO_ENTRE_JOGADORES, 0.3, 0.0)

func tem_jogadores_remotos() -> bool:
	return not _remotos.is_empty()

func inimigos_vivos() -> int:
	return _inimigos.size()

## Um inimigo por PontoDeInimigo da cena. O número dele na rede é a ordem do ponto, que é
## a mesma em todos os jogos porque a cena é a mesma.
func _criar_inimigos() -> void:
	var numero: int = 0
	for no in _pontos_de_inimigo.get_children():
		var ponto: PontoDeInimigo = no as PontoDeInimigo
		if ponto == null or ponto.perfil == null:
			continue
		var inimigo: Inimigo = CENA_DO_INIMIGO.instantiate() as Inimigo
		inimigo.perfil = ponto.perfil
		inimigo.numero_na_rede = numero
		inimigo.fantoche = not _sou_anfitriao
		inimigo.position = ponto.position
		inimigo.defeated.connect(_ao_derrotar)
		inimigo.puppet_hit.connect(_ao_acertar_um_fantoche)
		add_child(inimigo)
		_inimigos[numero] = inimigo
		numero += 1

# O que este jogo envia

## A posição vai relativa à dungeon, e o giro é o do modelo do personagem, que é o que
## vira; o corpo do jogador não gira.
func _enviar_o_jogador() -> void:
	var local: Vector3 = to_local(jogador_local.global_position)
	var personagem: Node3D = jogador_local.get_node("Personagem") as Node3D
	var animacao: AnimationPlayer = jogador_local.get_node("Personagem/AnimationPlayer") as AnimationPlayer
	LobbyManager.enviar_para_a_sala("jogador", {
		"p": [snappedf(local.x, 0.01), snappedf(local.y, 0.01), snappedf(local.z, 0.01)],
		"g": snappedf(personagem.rotation.y, 0.01),
		"a": String(animacao.current_animation),
	})

func _enviar_os_inimigos() -> void:
	var lista: Array = []
	for numero in _inimigos:
		lista.append(_inimigos[numero].estado_para_a_rede())
	LobbyManager.enviar_para_a_sala("inimigos", {"l": lista})

## O convidado acertou um fantoche: quem tira a vida é o anfitrião.
func _ao_acertar_um_fantoche(numero: int, quantidade: int) -> void:
	LobbyManager.enviar_para_a_sala("golpe", {"inimigo": numero, "dano": quantidade})

## Um inimigo do anfitrião acertou o fantoche de um jogador: quem perde a vida é o jogo
## dele.
func _ao_acertar_um_remoto(quantidade: int, id_do_jogador: String) -> void:
	LobbyManager.enviar_para_a_sala("dano", {"para": id_do_jogador, "quantidade": quantidade})

func _ao_derrotar(inimigo: Inimigo) -> void:
	_inimigos.erase(inimigo.numero_na_rede)
	if _sou_anfitriao:
		LobbyManager.enviar_para_a_sala("morreu", {"inimigo": inimigo.numero_na_rede})
	if _inimigos.is_empty():
		EventBus.notice_requested.emit("Todos os inimigos caíram. A saída está aberta.")

# O que este jogo recebe

func _ao_receber(de: String, tipo: String, campos: Dictionary) -> void:
	match tipo:
		"jogador":
			var p: Array = campos["p"]
			_remoto_de(de).aplicar_estado(to_global(Vector3(p[0], p[1], p[2])), campos["g"], StringName(campos["a"]))
		"inimigos":
			if _sou_anfitriao:
				return
			for estado: Array in campos["l"]:
				var inimigo: Inimigo = _inimigos.get(int(estado[0]), null)
				if inimigo != null:
					inimigo.aplicar_estado_da_rede(estado)
		"golpe":
			var alvo: Inimigo = _inimigos.get(int(campos["inimigo"]), null)
			if _sou_anfitriao and alvo != null:
				alvo.receber_dano(int(campos["dano"]), _remotos.get(de, null))
		"dano":
			if campos["para"] == NetworkManager.meu_id and jogador_local != null:
				jogador_local.call(&"receber_dano", int(campos["quantidade"]), null)
		"morreu":
			var morto: Inimigo = _inimigos.get(int(campos["inimigo"]), null)
			if not _sou_anfitriao and morto != null:
				morto.morrer_pela_rede()
		"saiu":
			_tirar_remoto(de)

## Quem saiu da equipe sem avisar (a conexão caiu) também some da dungeon.
func _ao_mudar_a_equipe() -> void:
	var ids_na_equipe: Array[String] = []
	for membro in LobbyManager.membros:
		ids_na_equipe.append(membro["id"])
	for id: String in _remotos.keys():
		if not ids_na_equipe.has(id):
			_tirar_remoto(id)

## O fantoche do jogador, criado na primeira mensagem dele.
func _remoto_de(id: String) -> JogadorRemoto:
	if _remotos.has(id):
		return _remotos[id]
	var remoto: JogadorRemoto = CENA_DO_JOGADOR_REMOTO.instantiate() as JogadorRemoto
	remoto.id_do_jogador = id
	add_child(remoto)
	remoto.definir_nome(NetworkManager.nome_de(id))
	remoto.hit_taken.connect(_ao_acertar_um_remoto.bind(id))
	_remotos[id] = remoto
	return remoto

func _tirar_remoto(id: String) -> void:
	if not _remotos.has(id):
		return
	_remotos[id].sumir()
	_remotos.erase(id)
	if _remotos.is_empty() and jogador_local == null:
		emptied.emit()
