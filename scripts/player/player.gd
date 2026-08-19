extends CharacterBody3D

@export var velocidade_andar: float = 3.0
@export var velocidade_correr: float = 6.0
@export var velocidade_rotacao: float = 10.0
@export var velocidade_dash: float = 12.0
@export var duracao_dash: float = 0.2
@export var cooldown_dash: float = 0.8
@export var velocidade_ataque: float = 1.6
@export var folga_pos_golpe: float = 0.1
@export var janela_combo_ataque: float = 0.6
@export var cooldown_ataque: float = 0.3

const CLIPES_COMBO_ATAQUE: Array[String] = ["attack-melee-left", "attack-melee-left", "attack-melee-right"]
const CLIPES_INTERACAO: Array[String] = ["interact-left", "interact-right"]

@onready var personagem: Node3D = $Personagem
@onready var animation_player: AnimationPlayer = $Personagem/AnimationPlayer
@onready var grade_solo: GradeSolo = $"../GradeSolo"
@onready var indicador_alvo: MeshInstance3D = $"../IndicadorAlvo"

var _tempo_dash_restante: float = 0.0
var _tempo_cooldown_restante: float = 0.0
var _direcao_dash: Vector3 = Vector3.ZERO

var _indice_combo: int = 0
var _indice_interacao: int = 0
var _tempo_ataque_restante: float = 0.0
var _tempo_movimento_travado_ataque_restante: float = 0.0
var _tempo_janela_combo_restante: float = 0.0
var _tempo_cooldown_ataque_restante: float = 0.0

func _physics_process(delta: float) -> void:
	_tempo_cooldown_restante = max(_tempo_cooldown_restante - delta, 0.0)
	_tempo_ataque_restante = max(_tempo_ataque_restante - delta, 0.0)
	_tempo_movimento_travado_ataque_restante = max(_tempo_movimento_travado_ataque_restante - delta, 0.0)
	_tempo_janela_combo_restante = max(_tempo_janela_combo_restante - delta, 0.0)
	_tempo_cooldown_ataque_restante = max(_tempo_cooldown_ataque_restante - delta, 0.0)

	if InputManager.equipar_1_pressionado():
		EquipmentManager.equipar_indice(-1)
	elif InputManager.equipar_2_pressionado():
		EquipmentManager.equipar_indice(0)
	elif InputManager.equipar_3_pressionado():
		EquipmentManager.equipar_indice(1)
	elif InputManager.equipar_4_pressionado():
		EquipmentManager.equipar_indice(2)
	elif InputManager.proxima_ferramenta_pressionada():
		EquipmentManager.ciclar(1)
	elif InputManager.ferramenta_anterior_pressionada():
		EquipmentManager.ciclar(-1)

	if _tempo_janela_combo_restante <= 0.0:
		_indice_combo = 0

	var ferramenta_equipada: Ferramenta = EquipmentManager.ferramenta_atual()
	indicador_alvo.visible = ferramenta_equipada != null
	if ferramenta_equipada != null:
		var celula_alvo: Vector2i = grade_solo.obter_celula_alvo(global_position, personagem.rotation.y)
		var posicao_local: Vector3 = grade_solo.map_to_local(Vector3i(celula_alvo.x, 0, celula_alvo.y))
		indicador_alvo.global_position = grade_solo.global_transform * posicao_local
		indicador_alvo.global_position.y += 0.01

	if _tempo_dash_restante <= 0.0 and _tempo_movimento_travado_ataque_restante <= 0.0 and _tempo_cooldown_restante <= 0.0 and InputManager.dash_pressionado():
		_direcao_dash = Vector3(sin(personagem.rotation.y), 0.0, cos(personagem.rotation.y))
		_tempo_dash_restante = duracao_dash
		_tempo_cooldown_restante = cooldown_dash + duracao_dash
		_indice_combo = 0
		_tempo_janela_combo_restante = 0.0

	if _tempo_dash_restante <= 0.0 and _tempo_ataque_restante <= 0.0 and _tempo_cooldown_ataque_restante <= 0.0 and InputManager.atacar_pressionado():
		if ferramenta_equipada == null:
			var nome_clipe: String = CLIPES_COMBO_ATAQUE[_indice_combo]
			_travar_movimento_pela_animacao(nome_clipe)
			_tempo_janela_combo_restante = janela_combo_ataque

			_indice_combo += 1
			if _indice_combo >= CLIPES_COMBO_ATAQUE.size():
				_indice_combo = 0
				_tempo_cooldown_ataque_restante = cooldown_ataque
				_tempo_janela_combo_restante = 0.0
		else:
			var celula_alvo: Vector2i = grade_solo.obter_celula_alvo(global_position, personagem.rotation.y)
			var acao_teve_efeito: bool = false
			if ferramenta_equipada.id_acao == &"enxada":
				acao_teve_efeito = grade_solo.arar(celula_alvo)
			elif ferramenta_equipada.id_acao == &"regador":
				acao_teve_efeito = grade_solo.molhar(celula_alvo)
			elif ferramenta_equipada.id_acao == &"picareta":
				acao_teve_efeito = grade_solo.remover(celula_alvo)

			if acao_teve_efeito:
				var nome_clipe_interacao: String = CLIPES_INTERACAO[_indice_interacao]
				_travar_movimento_pela_animacao(nome_clipe_interacao)
				_indice_interacao = (_indice_interacao + 1) % CLIPES_INTERACAO.size()

	if _tempo_dash_restante > 0.0:
		_tempo_dash_restante = max(_tempo_dash_restante - delta, 0.0)

		velocity.x = _direcao_dash.x * velocidade_dash
		velocity.z = _direcao_dash.z * velocidade_dash

		_atualizar_animacao(Vector3.ZERO, false, true)
	elif _tempo_movimento_travado_ataque_restante > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var entrada: Vector2 = InputManager.obter_direcao_movimento()
		var direcao: Vector3 = Vector3(entrada.x, 0.0, entrada.y)

		if direcao != Vector3.ZERO and _indice_combo != 0:
			_indice_combo = 0
			_tempo_janela_combo_restante = 0.0

		var esta_correndo: bool = direcao != Vector3.ZERO and InputManager.correr_pressionado()
		var velocidade_atual: float = velocidade_correr if esta_correndo else velocidade_andar

		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual

		if direcao != Vector3.ZERO:
			var angulo_alvo: float = atan2(direcao.x, direcao.z)
			personagem.rotation.y = lerp_angle(personagem.rotation.y, angulo_alvo, velocidade_rotacao * delta)

		_atualizar_animacao(direcao, esta_correndo, false)

	move_and_slide()

func _travar_movimento_pela_animacao(nome_clipe: String) -> void:
	animation_player.play(nome_clipe, -1.0, velocidade_ataque)

	var duracao_clipe: float = animation_player.get_animation(nome_clipe).length / velocidade_ataque
	_tempo_ataque_restante = duracao_clipe
	_tempo_movimento_travado_ataque_restante = duracao_clipe + folga_pos_golpe

func _atualizar_animacao(direcao: Vector3, esta_correndo: bool, esta_dando_dash: bool) -> void:
	var animacao_alvo: String = "idle"
	if esta_dando_dash:
		animacao_alvo = "jump"
	elif direcao != Vector3.ZERO:
		animacao_alvo = "sprint" if esta_correndo else "walk"

	if animation_player.current_animation != animacao_alvo:
		animation_player.play(animacao_alvo)
