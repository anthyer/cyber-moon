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

@export var volume_andando_db: float = -6.0
@export var volume_correndo_db: float = -2.0

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
	var fluxo: AudioStream = banco.sortear(superficie)
	if fluxo == null:
		return
	var volume: float = volume_correndo_db if clipe == &"sprint" else volume_andando_db
	if superficie == &"agua":
		volume -= 12.0
	
	# Como o áudio foi cortado fisicamente para apenas 1 passo (0.45s), tocamos ele inteiro
	_tocador_atual = AudioManager.tocar_sfx(
		fluxo,
		get_parent().global_position,
		volume + banco.sortear_volume_db() + 14.0,
		banco.sortear_tom()
	)

func _parar_passo() -> void:
	if _tocador_atual != null and is_instance_valid(_tocador_atual):
		if _tocador_atual.playing:
			_tocador_atual.stop()
		_tocador_atual = null

func _superficie_sob_o_pe() -> StringName:
	var grade_solo = get_node_or_null(^"../../GradeSolo")
	if grade_solo != null and grade_solo.has_method("local_to_map"):
		var ponto_local = grade_solo.to_local(get_parent().global_position)
		var celula = grade_solo.local_to_map(ponto_local)
		var item_id = grade_solo.get_cell_item(celula)
		if item_id != GridMap.INVALID_CELL_ITEM:
			var nome_item = grade_solo.mesh_library.get_item_name(item_id).to_lower()
			return _superficie_do_nome(nome_item)
			
	if not _raio.is_colliding():
		return banco.superficie_padrao
	var corpo: Object = _raio.get_collider()
	if corpo == null:
		return banco.superficie_padrao
		
	var parent_name = corpo.get_parent().name if corpo.get_parent() else ""
	var sup_pelo_nome = _superficie_do_nome(parent_name.to_lower())
	if sup_pelo_nome != banco.superficie_padrao:
		return sup_pelo_nome

	var meta_sup = corpo.get_meta(&"superficie", banco.superficie_padrao)
	return meta_sup

func _superficie_do_nome(nome_do_arquivo: String) -> StringName:
	var superficies = [
		["watered", &"agua"],
		["water", &"agua"],
		["river", &"agua"],
		["lake", &"agua"],
		["piso", &"agua"],
		["road", &"asfalto"],
		["driveway", &"asfalto"],
		["sidewalk", &"pedra"],
		["path_stone", &"pedra"],
		["stone", &"pedra"],
		["cliff", &"pedra"],
		["rock", &"pedra"],
		["bridge", &"madeira"],
		["log_", &"madeira"],
		["plank", &"madeira"],
		["fence", &"madeira"],
		["crate", &"madeira"],
		["tree", &"madeira"],
		["building", &"metal"],
		["detail_", &"metal"],
		["tank", &"metal"],
		["silo", &"metal"],
		["ground_path", &"terra"],
		["dirt", &"terra"],
		["soil", &"terra"],
		["platform_grass", &"agua"],
		["ground_grass", &"agua"]
	]
	for par in superficies:
		if nome_do_arquivo.contains(par[0]):
			return par[1]
	return banco.superficie_padrao
