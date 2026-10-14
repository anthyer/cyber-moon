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

const PASTA_DAS_DEFINICOES: String = "res://resources/dungeons/"
const CAMINHO_DAS_FAIXAS_DE_MATERIAL: String = "res://resources/combat/faixas_de_material.tres"
## Longe o bastante para nada da fazenda ver ou ouvir a dungeon, nem os inimigos de uma
## perceberem o jogador na outra.
const POSICAO_DA_DUNGEON: Vector3 = Vector3(0.0, 0.0, 400.0)
const CENA_DO_SOPRO: PackedScene = preload("res://scenes/effects/poeira_de_passo.tscn")
const COR_DO_SOPRO: Color = Color(0.3, 0.95, 1.0)

## O número do dia da última vez que o jogador entrou na dungeon, para as falas que
## comentam que ele acabou de sair de lá. Zero quando nunca entrou.
var dia_da_ultima_visita: int = 0

## Ids das dungeons cujo chefe o jogador já venceu alguma vez. É o que libera a seguinte.
var chefes_vencidos: Dictionary[StringName, bool] = {}
## Id da dungeon para o dia da última recompensa de chefe. A recompensa grande sai uma vez
## por dia de jogo, por dungeon.
var dia_da_ultima_recompensa: Dictionary[StringName, int] = {}

var _dungeon: Dungeon
var _definicoes: Array[DefinicaoDeDungeon] = []
var _jogador_dentro: bool = false
var _posicao_de_volta: Vector3
## Depois de cair na dungeon, a cena só é apagada quando o jogador acorda em casa. Apagar
## antes tiraria o chão de baixo do personagem caído.
var _apagar_ao_acordar: bool = false

func _ready() -> void:
	_carregar_definicoes()
	LobbyManager.dungeon_started.connect(entrar)
	LobbyManager.room_closed.connect(_ao_fechar_a_sala)
	StatusManager.player_fainted.connect(_ao_desmaiar)
	StatusManager.player_woke_up.connect(_ao_acordar)

func esta_na_dungeon() -> bool:
	return _jogador_dentro

## As dungeons do jogo, na ordem do lobby.
func definicoes() -> Array[DefinicaoDeDungeon]:
	return _definicoes

func definicao_de(id: StringName) -> DefinicaoDeDungeon:
	for definicao in _definicoes:
		if definicao.id == id:
			return definicao
	return null

## A dungeon em que o jogador está agora, ou null fora dela.
func definicao_atual() -> DefinicaoDeDungeon:
	return _dungeon.definicao if _dungeon != null else null

func dungeon_atual() -> Dungeon:
	return _dungeon

## A primeira dungeon está aberta desde o começo. As outras abrem quando o chefe da
## anterior foi vencido.
func esta_liberada(definicao: DefinicaoDeDungeon) -> bool:
	return definicao != null and (definicao.requer == &"" or chefes_vencidos.has(definicao.requer))

func chefe_ja_foi_vencido(id: StringName) -> bool:
	return chefes_vencidos.has(id)

## Falso quando a recompensa do chefe desta dungeon já foi pega hoje.
func pode_receber_recompensa(id: StringName) -> bool:
	return dia_da_ultima_recompensa.get(id, 0) != DayCycleManager.numero_do_dia

## Entrega a recompensa do chefe: créditos e materiais raros, com o bônus do objetivo
## paralelo, e o troféu na primeira vitória de todas. Marca o chefe como vencido, o que
## libera a dungeon seguinte. Devolve o que foi dado, para a tela mostrar:
## {"creditos", "materiais" (lista de Item), "trofeu" (Item ou null), "primeira_vez"}.
## Dicionário vazio quando a recompensa de hoje já foi pega.
func receber_recompensa(definicao: DefinicaoDeDungeon, objetivo_cumprido: bool) -> Dictionary:
	if definicao == null or not pode_receber_recompensa(definicao.id):
		return {}
	var primeira_vez: bool = not chefes_vencidos.has(definicao.id)
	chefes_vencidos[definicao.id] = true
	dia_da_ultima_recompensa[definicao.id] = DayCycleManager.numero_do_dia
	var creditos: int = definicao.creditos + (definicao.creditos_do_objetivo if objetivo_cumprido else 0)
	var quantidade: int = definicao.materiais_raros + (definicao.materiais_raros_do_objetivo if objetivo_cumprido else 0)
	EconomyManager.receber(creditos)
	var materiais: Array[Item] = []
	var faixas: FaixasDeMaterial = load(CAMINHO_DAS_FAIXAS_DE_MATERIAL) as FaixasDeMaterial
	for indice in quantidade:
		if faixas != null and not faixas.raros.is_empty():
			materiais.append(faixas.raros.pick_random())
	for item in materiais:
		_dar_item(item)
	var trofeu: Item = definicao.trofeu if primeira_vez else null
	if trofeu != null:
		_dar_item(trofeu)
	return {"creditos": creditos, "materiais": materiais, "trofeu": trofeu, "primeira_vez": primeira_vez}

## Cria a dungeon escolhida e leva o jogador. Chamado pelo LobbyManager quando a equipe
## começa, e vale igual para quem joga sozinho. Sem id, entra na primeira da lista.
func entrar(dungeon_id: String = "") -> void:
	var jogador: CharacterBody3D = _jogador()
	var definicao: DefinicaoDeDungeon = definicao_de(StringName(dungeon_id)) if dungeon_id != "" else (_definicoes[0] if not _definicoes.is_empty() else null)
	if _dungeon != null or jogador == null or definicao == null:
		return
	_dungeon = (load(definicao.cena) as PackedScene).instantiate() as Dungeon
	_dungeon.definicao = definicao
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
	dia_da_ultima_visita = DayCycleManager.numero_do_dia
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

## Item que não cabe no inventário cai aos pés do jogador, em vez de se perder.
func _dar_item(item: Item) -> void:
	var sobra: int = InventoryManager.adicionar_item(item, 1)
	var jogador: CharacterBody3D = _jogador()
	if sobra > 0 and jogador != null:
		ItemNoMundo.soltar(item, sobra, jogador.global_position + Vector3.UP * 0.3, get_tree().current_scene)

func _carregar_definicoes() -> void:
	_definicoes.clear()
	for arquivo in DirAccess.get_files_at(PASTA_DAS_DEFINICOES):
		var nome: String = arquivo.trim_suffix(".remap")
		if not nome.ends_with(".tres"):
			continue
		var definicao: DefinicaoDeDungeon = load(PASTA_DAS_DEFINICOES + nome) as DefinicaoDeDungeon
		if definicao != null:
			_definicoes.append(definicao)
	_definicoes.sort_custom(func(a: DefinicaoDeDungeon, b: DefinicaoDeDungeon) -> bool: return a.ordem < b.ordem)

func _jogador() -> CharacterBody3D:
	return get_tree().get_first_node_in_group(&"jogador") as CharacterBody3D

func _soltar_sopro(posicao: Vector3) -> void:
	EfeitoDeParticulas.soltar(CENA_DO_SOPRO, posicao + Vector3.UP * 0.4, COR_DO_SOPRO, 16, get_tree().current_scene)

# Save

func exportar_estado() -> Dictionary:
	var recompensas: Dictionary = {}
	for id: StringName in dia_da_ultima_recompensa:
		recompensas[String(id)] = dia_da_ultima_recompensa[id]
	var vencidos: Array = []
	for id: StringName in chefes_vencidos:
		vencidos.append(String(id))
	return {"dia_da_ultima_visita": dia_da_ultima_visita, "chefes_vencidos": vencidos, "dia_da_ultima_recompensa": recompensas}

func importar_estado(dados: Dictionary) -> void:
	dia_da_ultima_visita = int(dados.get("dia_da_ultima_visita", 0))
	chefes_vencidos.clear()
	dia_da_ultima_recompensa.clear()
	for id: String in dados.get("chefes_vencidos", []):
		chefes_vencidos[StringName(id)] = true
	for id: String in dados.get("dia_da_ultima_recompensa", {}):
		dia_da_ultima_recompensa[StringName(id)] = int(dados["dia_da_ultima_recompensa"][id])
