extends Node

## Leva o jogador para a dungeon e traz de volta.
##
## A dungeon não é uma troca de cena. Ela é criada longe da fazenda, dentro da mesma fase,
## e o jogador é levado até lá: o personagem, a câmera, a HUD e o chat continuam os mesmos,
## e a fazenda fica intacta para a volta (o jogo ainda não salva, então trocar de cena
## perderia as plantas). Ao sair, a cena da dungeon é apagada.
##
## Lá dentro o relógio para. A luz e a chuva reagem aos sinais dungeon_entered e
## dungeon_left do EventBus.

const CAMINHO_DA_CENA: String = "res://scenes/levels/dungeon.tscn"
## Longe o bastante para nada da fazenda ver ou ouvir a dungeon, nem os inimigos de uma
## perceberem o jogador na outra.
const POSICAO_DA_DUNGEON: Vector3 = Vector3(0.0, 0.0, 400.0)
const CENA_DO_SOPRO: PackedScene = preload("res://scenes/effects/poeira_de_passo.tscn")
const COR_DO_SOPRO: Color = Color(0.3, 0.95, 1.0)

var _dungeon: Dungeon
var _jogador_dentro: bool = false
var _posicao_de_volta: Vector3
## Depois de cair na dungeon, a cena só é apagada quando o jogador acorda em casa. Apagar
## antes tiraria o chão de baixo do personagem caído.
var _apagar_ao_acordar: bool = false

func _ready() -> void:
	LobbyManager.dungeon_started.connect(entrar)
	LobbyManager.room_closed.connect(_ao_fechar_a_sala)
	StatusManager.player_fainted.connect(_ao_desmaiar)
	StatusManager.player_woke_up.connect(_ao_acordar)

func esta_na_dungeon() -> bool:
	return _jogador_dentro

## Cria a dungeon e leva o jogador. Chamado pelo LobbyManager quando a equipe começa, e
## vale igual para quem joga sozinho.
func entrar() -> void:
	var jogador: CharacterBody3D = _jogador()
	if _dungeon != null or jogador == null:
		return
	_dungeon = (load(CAMINHO_DA_CENA) as PackedScene).instantiate() as Dungeon
	_dungeon.position = POSICAO_DA_DUNGEON
	_dungeon.emptied.connect(_ao_esvaziar)
	get_tree().current_scene.add_child(_dungeon)

	_posicao_de_volta = jogador.global_position
	_soltar_sopro(jogador.global_position)
	jogador.global_position = _dungeon.ponto_de_entrada(_minha_ordem_na_equipe())
	jogador.velocity = Vector3.ZERO
	_soltar_sopro(jogador.global_position)
	_dungeon.jogador_local = jogador
	_jogador_dentro = true
	_apagar_ao_acordar = false
	DayCycleManager.tempo_congelado = true
	EventBus.dungeon_entered.emit()

## Sai pela porta: volta para o portal da fazenda. Quem sai deixa a equipe; se era o
## anfitrião, a sala acaba e o convidado também volta.
func sair() -> void:
	if not _jogador_dentro:
		return
	_voltar_para_a_fazenda()
	LobbyManager.enviar_para_a_sala("saiu")
	LobbyManager.sair()
	_apagar()

func _voltar_para_a_fazenda() -> void:
	var jogador: CharacterBody3D = _jogador()
	if jogador != null:
		_soltar_sopro(jogador.global_position)
		jogador.global_position = _posicao_de_volta
		jogador.velocity = Vector3.ZERO
		_soltar_sopro(jogador.global_position)
	_deixar()

## O jogador não está mais na dungeon, mas a cena dela pode continuar existindo.
func _deixar() -> void:
	_jogador_dentro = false
	if _dungeon != null:
		_dungeon.jogador_local = null
	DayCycleManager.tempo_congelado = false
	EventBus.dungeon_left.emit()

func _apagar() -> void:
	if _dungeon != null:
		_dungeon.queue_free()
		_dungeon = null
	_apagar_ao_acordar = false

## Quem morre volta sozinho para a fazenda, pelo desmaio de sempre (acorda em casa no dia
## seguinte). O anfitrião que morre com alguém ainda lá dentro continua simulando os
## inimigos de longe, para o parceiro seguir jogando.
func _ao_desmaiar(_motivo: StatusManager.Motivo) -> void:
	if not _jogador_dentro:
		return
	_deixar()
	LobbyManager.enviar_para_a_sala("saiu")
	if LobbyManager.sou_anfitriao() and _dungeon.tem_jogadores_remotos():
		return
	LobbyManager.sair()
	_apagar_ao_acordar = true

func _ao_acordar(_motivo: StatusManager.Motivo) -> void:
	if _apagar_ao_acordar:
		_apagar()

## O anfitrião estava fora (morreu) e o último parceiro saiu: não há mais para quem
## simular.
func _ao_esvaziar() -> void:
	if _jogador_dentro:
		return
	LobbyManager.sair()
	_apagar()

## A sala acabou: o anfitrião saiu, ou a conexão caiu. A dungeon acaba para quem ficou.
func _ao_fechar_a_sala() -> void:
	if _dungeon == null:
		return
	if _jogador_dentro:
		_voltar_para_a_fazenda()
		EventBus.notice_requested.emit("A equipe se desfez. Você voltou para a fazenda.")
	_apagar()

## 0 para o anfitrião ou para quem está sozinho, 1 para o primeiro convidado. Serve para
## cada um nascer num ponto diferente da entrada.
func _minha_ordem_na_equipe() -> int:
	for indice in LobbyManager.membros.size():
		if LobbyManager.membros[indice]["id"] == NetworkManager.meu_id:
			return indice
	return 0

func _jogador() -> CharacterBody3D:
	return get_tree().get_first_node_in_group(&"jogador") as CharacterBody3D

func _soltar_sopro(posicao: Vector3) -> void:
	EfeitoDeParticulas.soltar(CENA_DO_SOPRO, posicao + Vector3.UP * 0.4, COR_DO_SOPRO, 16, get_tree().current_scene)
