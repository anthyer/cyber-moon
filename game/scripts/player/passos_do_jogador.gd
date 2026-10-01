extends Node

## Toca o som de passo do jogador no momento em que o pé encosta no chão.
##
## O disparo é amarrado à fase do clipe de animação, e não a um intervalo de tempo
## fixo nem à distância percorrida, porque só assim o som acompanha a animação
## quando ela muda de velocidade. As animações vêm dentro do .glb do pacote Kenney
## e não aceitam method track sem reimportar o modelo, então em vez de marcar o
## frame do contato dentro da animação, o script observa a posição do clipe e
## dispara quando ela cruza as fases configuradas abaixo.

@export var caminho_animation_player: NodePath = ^"../Personagem/AnimationPlayer"
@export var caminho_raio_superficie: NodePath = ^"../RaioSuperficie"
@export var banco: BancoDePassos

## Fração do clipe (de 0.0 a 1.0) em que cada pé encosta no chão. Dois valores por
## clipe porque o ciclo de caminhada tem dois passos. Ajuste olhando a animação
## rodando em câmera lenta no editor.
@export var fases_andando: Array[float] = [0.15, 0.65]
@export var fases_correndo: Array[float] = [0.10, 0.60]

## Volumes acima de zero porque os clipes de passo foram gravados baixos em relação à
## música e aos efeitos. O ajuste fino por superfície fica no BancoDePassos.
## Poeira que sai do pé a cada passo, na cor da superfície. Vazio não mostra nada.
@export var efeito_de_passo: PackedScene
@export var particulas_andando: int = 5
@export var particulas_correndo: int = 9

@export var volume_andando_db: float = 8.0
@export var volume_correndo_db: float = 12.0

@onready var _animation_player: AnimationPlayer = get_node(caminho_animation_player)
@onready var _raio: RayCast3D = get_node(caminho_raio_superficie)

var _fase_anterior: float = 0.0
var _clipe_anterior: StringName = &""
var _tocador_atual: AudioStreamPlayer3D = null

func _physics_process(_delta: float) -> void:
	var clipe: StringName = _animation_player.current_animation
	var fases: Array[float] = _fases_do_clipe(clipe)
	if fases.is_empty():
		_fase_anterior = 0.0
		_clipe_anterior = clipe
		_parar_passo()
		return

	var duracao: float = _animation_player.current_animation_length
	if duracao <= 0.0:
		return
	var fase_atual: float = _animation_player.current_animation_position / duracao

	if clipe != _clipe_anterior:
		_clipe_anterior = clipe
		_fase_anterior = fase_atual
		_parar_passo()
		return

	for fase in fases:
		if _cruzou(_fase_anterior, fase_atual, fase):
			_tocar_passo(clipe)
			break

	_fase_anterior = fase_atual

func _fases_do_clipe(clipe: StringName) -> Array[float]:
	match clipe:
		&"walk":
			return fases_andando
		&"sprint":
			return fases_correndo
		_:
			return []

## Detecta se a fase alvo ficou para trás entre o quadro anterior e o atual,
## tratando o caso em que o clipe deu a volta e a posição voltou para perto de zero.
func _cruzou(anterior: float, atual: float, alvo: float) -> bool:
	if atual >= anterior:
		return anterior < alvo and atual >= alvo
	return anterior < alvo or atual >= alvo

func _tocar_passo(clipe: StringName) -> void:
	_parar_passo()
	if banco == null:
		return
	var superficie: StringName = _superficie_sob_o_pe()
	# A poeira vem antes do som porque não depende de haver clipe para a superfície.
	_soltar_poeira(clipe, superficie)
	var fluxo: AudioStream = banco.sortear(superficie)
	if fluxo == null:
		return
	var volume: float = volume_correndo_db if clipe == &"sprint" else volume_andando_db
	volume += banco.ajuste_de_volume_db(superficie) + banco.sortear_volume_db()
	_tocador_atual = AudioManager.tocar_sfx(
		fluxo,
		get_parent().global_position,
		volume,
		banco.sortear_tom()
	)

## A poeira fica presa à fase, e não ao jogador, para ficar onde o pé pisou enquanto
## ele segue andando.
func _soltar_poeira(clipe: StringName, superficie: StringName) -> void:
	if efeito_de_passo == null:
		return
	var jogador: Node3D = get_parent() as Node3D
	var quantidade: int = particulas_correndo if clipe == &"sprint" else particulas_andando
	EfeitoDeParticulas.soltar(efeito_de_passo, jogador.global_position + Vector3.UP * 0.03, banco.cor_da_poeira(superficie), quantidade, jogador.get_parent())

func _parar_passo() -> void:
	if _tocador_atual != null and is_instance_valid(_tocador_atual):
		if _tocador_atual.playing:
			_tocador_atual.stop()
		_tocador_atual = null

## A grade de solo vem primeiro porque as células do GridMap não têm corpo de colisão
## para o raio acertar. Depois vale o nome do modelo sob o pé e, por último, a
## metadata gravada na importação.
func _superficie_sob_o_pe() -> StringName:
	var grade_solo: GridMap = get_node_or_null(^"../../GradeSolo") as GridMap
	if grade_solo != null:
		var ponto_local: Vector3 = grade_solo.to_local(get_parent().global_position)
		var celula: Vector3i = grade_solo.local_to_map(ponto_local)
		# A terra arada só existe no andar zero da grade. Sem fixar o andar, a altura do
		# jogador cai em outro andar e a célula parece sempre vazia.
		celula.y = 0
		var item_id: int = grade_solo.get_cell_item(celula)
		if item_id != GridMap.INVALID_CELL_ITEM:
			return Superficies.do_nome(grade_solo.mesh_library.get_item_name(item_id))

	if not _raio.is_colliding():
		return banco.superficie_padrao
	var corpo: Node = _raio.get_collider() as Node
	if corpo == null:
		return banco.superficie_padrao

	var no_do_modelo: Node = corpo.get_parent()
	if no_do_modelo != null and Superficies.reconhece(no_do_modelo.name):
		return Superficies.do_nome(no_do_modelo.name)

	return corpo.get_meta(&"superficie", banco.superficie_padrao)
