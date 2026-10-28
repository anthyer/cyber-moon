class_name EfeitosDoJogo
extends Node

## Solta o efeito de partículas de cada ação do jogo.
##
## Este nó escuta os sinais que os sistemas já emitem e põe o efeito no lugar certo. Os
## sistemas não sabem que partículas existem: a GradeSolo avisa que arou, e é aqui que a
## terra salta. Tirar este nó da fase tira todos os efeitos, sem quebrar nada.
##
## São quatro cenas de efeito, uma por tipo de movimento, e a cor e a quantidade mudam por
## ação (a tabela EFEITOS). Os efeitos são pequenos e rápidos de propósito: o jogo é visto
## de cima e de longe, e efeito grande tapa o personagem.

const SOPRO: PackedScene = preload("res://scenes/effects/poeira_de_passo.tscn")
const ESTOURO: PackedScene = preload("res://scenes/effects/estouro.tscn")
const JORRO: PackedScene = preload("res://scenes/effects/jorro.tscn")
const SUBIDA: PackedScene = preload("res://scenes/effects/subida_lenta.tscn")

## Cada ação para [cena, cor, quantidade de partículas, altura acima do ponto].
const EFEITOS: Dictionary = {
	# Fazenda
	&"arar": [ESTOURO, Color(0.45, 0.31, 0.2), 10, 0.1],
	&"molhar": [JORRO, Color(0.45, 0.75, 1.0), 14, 0.5],
	&"desfazer_solo": [ESTOURO, Color(0.36, 0.26, 0.18), 12, 0.1],
	&"plantar": [SOPRO, Color(0.5, 0.36, 0.24), 8, 0.08],
	&"crescer": [SUBIDA, Color(0.5, 1.0, 0.45), 6, 0.2],
	&"murchar": [JORRO, Color(0.6, 0.5, 0.25), 8, 0.5],
	&"arrancar": [ESTOURO, Color(0.4, 0.7, 0.3), 10, 0.25],
	&"colher": [SUBIDA, Color(0.5, 0.9, 0.4), 12, 0.25],
	&"coletar": [ESTOURO, Color(1.0, 0.95, 0.6), 6, 0.3],
	# Combate e status. O jogo não tem sangue: nenhum efeito de dano é vermelho, nem no
	# jogador nem no inimigo. O golpe solta faísca clara, como metal batendo.
	&"acerto": [ESTOURO, Color(1.0, 0.85, 0.4), 10, 0.35],
	&"acerto_eletrico": [ESTOURO, Color(0.3, 0.95, 1.0), 14, 0.35],
	&"dano_no_jogador": [ESTOURO, Color(1.0, 1.0, 1.0), 10, 0.35],
	&"impacto_de_projetil": [ESTOURO, Color(1.0, 0.9, 0.5), 6, 0.0],
	&"inimigo_caiu": [ESTOURO, Color(0.8, 0.88, 1.0), 22, 0.3],
	&"inimigo_surge": [SUBIDA, Color(0.75, 0.6, 1.0), 18, 0.1],
	&"dash": [SOPRO, Color(0.85, 0.85, 0.8), 10, 0.05],
	&"comer": [SUBIDA, Color(0.5, 1.0, 0.6), 10, 0.3],
	&"subir_de_nivel": [SUBIDA, Color(1.0, 0.85, 0.3), 26, 0.2],
	&"desmaiar": [SUBIDA, Color(1.0, 1.0, 0.6), 8, 0.6],
	# Mundo
	&"estacao": [SUBIDA, Color(1.0, 1.0, 1.0), 24, 0.3],
	&"marco": [SUBIDA, Color(0.3, 0.95, 1.0), 26, 0.3],
	# Saque (plano 24)
	&"saque_raro": [SUBIDA, Color(1.0, 0.75, 0.2), 14, 0.2],
	# Vendinha da demo: o crédito que sai na compra e o que entra na venda.
	&"comprar": [ESTOURO, Color(0.3, 0.95, 1.0), 10, 0.6],
	&"vender": [SUBIDA, Color(1.0, 0.85, 0.35), 16, 0.4],
	# Água.
	&"resgate_da_agua": [JORRO, Color(0.45, 0.75, 1.0), 16, 0.4],
	# Interação (plano 28): um sopro pequeno no alvo novo, para o olho achar o destaque.
	&"alvo_de_interacao": [SOPRO, Color(1.0, 0.92, 0.6), 5, 0.25],
}

const ID_DO_BASTAO_DE_CHOQUE: StringName = &"bastao_choque"
## O teto de efeitos novos por quadro. Na virada do dia dezenas de plantas crescem e todo
## o solo seca ou molha de uma vez; sem teto, seriam centenas de emissores no mesmo
## quadro. O que passar do teto simplesmente não aparece.
const MAXIMO_POR_QUADRO: int = 10
## Efeito mais longe que isto do jogador não é solto: não seria visto.
const DISTANCIA_MAXIMA: float = 22.0

@export var caminho_da_grade_de_solo: NodePath = ^"../GradeSolo"

@onready var _grade: GradeSolo = get_node_or_null(caminho_da_grade_de_solo) as GradeSolo

var _soltos_neste_quadro: int = 0
## Para o estouro de subir de nível só aparecer quando o nível sobe, e não ao carregar um
## jogo salvo, que também emite level_changed.
var _nivel_conhecido: int = 1
## Ações que aconteceram com o jogo pausado (a loja e o baú pausam), à espera de a tela
## fechar para o efeito aparecer.
var _acoes_a_mostrar: Array[StringName] = []

func _ready() -> void:
	_nivel_conhecido = StatusManager.nivel
	# Fazenda.
	EventBus.tile_plowed.connect(_na_celula.bind(&"arar"))
	EventBus.tile_watered.connect(_na_celula.bind(&"molhar"))
	EventBus.tile_removed.connect(_na_celula.bind(&"desfazer_solo"))
	EventBus.crop_planted.connect(func(celula: Vector2i, _cultivo: Cultivo) -> void: _na_celula(celula, &"plantar"))
	EventBus.crop_grown.connect(func(celula: Vector2i, _estagio: int) -> void: _na_celula(celula, &"crescer"))
	EventBus.crop_withered.connect(_na_celula.bind(&"murchar"))
	EventBus.crop_removed.connect(_na_celula.bind(&"arrancar"))
	EventBus.crop_harvested.connect(func(_cultivo: Cultivo, _quantidade: int, celula: Vector2i) -> void: _na_celula(celula, &"colher"))
	EventBus.item_picked_up.connect(func(_item: Item, _quantidade: int) -> void: _no_jogador(&"coletar"))
	# Combate e status.
	EventBus.damage_dealt.connect(_ao_causar_dano)
	EventBus.enemy_defeated.connect(_ao_cair_inimigo)
	EventBus.enemy_spawned.connect(_soltar.bind(&"inimigo_surge"))
	EventBus.projectile_impacted.connect(_soltar.bind(&"impacto_de_projetil"))
	EventBus.player_dashed.connect(_soltar.bind(&"dash"))
	EventBus.item_consumed.connect(func(_consumivel: Consumivel) -> void: _no_jogador(&"comer"))
	StatusManager.level_changed.connect(_ao_mudar_nivel)
	StatusManager.player_fainted.connect(func(_motivo: StatusManager.Motivo) -> void: _no_jogador(&"desmaiar"))
	# Mundo.
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	EventBus.city_expansion_blocked.connect(func(_marco: String) -> void: _no_jogador(&"marco"))
	# Saque e vendinha.
	EventBus.rare_loot_dropped.connect(func(posicao: Vector3, cor: Color) -> void: _soltar(posicao, &"saque_raro", cor))
	EconomyManager.item_purchased.connect(func(_item: Item, _quantidade: int) -> void: _aguardar_tela(&"comprar"))
	EconomyManager.sale_completed.connect(func(_total: int, _itens: int) -> void: _aguardar_tela(&"vender"))
	EventBus.player_rescued.connect(_soltar.bind(&"resgate_da_agua"))
	EventBus.interaction_target_changed.connect(_ao_mudar_alvo_de_interacao)

## Este nó para junto com o jogo. A compra e a venda acontecem em telas que pausam o
## jogo, então o efeito espera aqui e sai quando a tela fecha, uma vez por tipo de ação.
func _process(_delta: float) -> void:
	_soltos_neste_quadro = 0
	for acao in _acoes_a_mostrar:
		_no_jogador(acao)
	_acoes_a_mostrar.clear()

func _aguardar_tela(acao: StringName) -> void:
	if not _acoes_a_mostrar.has(acao):
		_acoes_a_mostrar.append(acao)

## Solta o efeito de uma ação num ponto do mundo. A cor pode ser trocada por quem chama,
## quando ela depende de algo do jogo (a cor do inimigo, a da estação).
func _soltar(posicao: Vector3, acao: StringName, cor: Color = Color.TRANSPARENT) -> void:
	var fase: Node = get_parent()
	if _soltos_neste_quadro >= MAXIMO_POR_QUADRO or fase == null or _longe_demais(posicao):
		return
	_soltos_neste_quadro += 1
	var efeito: Array = EFEITOS[acao]
	var cor_usada: Color = efeito[1] if cor == Color.TRANSPARENT else cor
	EfeitoDeParticulas.soltar(efeito[0], posicao + Vector3.UP * efeito[3], cor_usada, efeito[2], fase)

func _ao_mudar_alvo_de_interacao(alvo: Node3D) -> void:
	if alvo != null:
		_soltar(alvo.global_position, &"alvo_de_interacao")

func _na_celula(celula: Vector2i, acao: StringName) -> void:
	if _grade != null:
		_soltar(_grade.centro_da_celula_no_mundo(celula), acao)

func _no_jogador(acao: StringName) -> void:
	var jogador: Node3D = _jogador()
	if jogador != null:
		_soltar(jogador.global_position, acao)

## Quem levou o golpe decide a cor: branca no jogador; nos outros, a faísca é amarela, ou
## elétrica quando o golpe veio do bastão de choque. Nunca vermelha: o jogo não tem sangue.
func _ao_causar_dano(alvo: Node3D, _quantidade: int) -> void:
	if alvo == null or not is_instance_valid(alvo):
		return
	if alvo.is_in_group(&"jogador"):
		_soltar(alvo.global_position, &"dano_no_jogador")
		return
	var na_mao: Item = EquipmentManager.item_na_mao()
	var eletrico: bool = na_mao != null and na_mao.id == ID_DO_BASTAO_DE_CHOQUE
	_soltar(alvo.global_position, &"acerto_eletrico" if eletrico else &"acerto")

## A cor é fixa, de metal, e não a do perfil do inimigo: o drone é avermelhado, e o
## estouro dele pareceria sangue.
func _ao_cair_inimigo(_perfil: PerfilInimigo, posicao: Vector3) -> void:
	_soltar(posicao, &"inimigo_caiu")

func _ao_mudar_nivel(novo_nivel: int) -> void:
	if novo_nivel > _nivel_conhecido:
		_no_jogador(&"subir_de_nivel")
	_nivel_conhecido = novo_nivel

## A virada de estação solta folhas na cor da grama da estação nova, em volta do jogador.
func _ao_mudar_estacao(_nova: StringName) -> void:
	var jogador: Node3D = _jogador()
	var perfil: PerfilEstacao = SeasonManager.perfil_atual()
	if jogador == null or perfil == null:
		return
	var cor: Color = (Color(0.52, 0.78, 0.41) * perfil.cor_da_grama).clamp()
	cor.a = 1.0
	_soltar(jogador.global_position, &"estacao", cor)

func _longe_demais(posicao: Vector3) -> bool:
	var jogador: Node3D = _jogador()
	return jogador != null and jogador.global_position.distance_to(posicao) > DISTANCIA_MAXIMA

func _jogador() -> Node3D:
	return get_tree().get_first_node_in_group(&"jogador") as Node3D
